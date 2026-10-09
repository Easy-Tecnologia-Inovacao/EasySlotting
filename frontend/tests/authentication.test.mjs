import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import ts from 'typescript'

function storage() {
  const values = new Map()
  return {
    getItem: (key) => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, String(value)),
    removeItem: (key) => values.delete(key)
  }
}

function environment() {
  const localStorage = storage(), sessionStorage = storage()
  const modules = {}
  const context = { localStorage, sessionStorage, Date, crypto: globalThis.crypto,
    window: { location: { hostname: 'localhost', protocol: 'http:', assign: () => {} } } }
  function load(name) {
    if (modules[name]) return modules[name]
    const path = new URL('../src/services/' + name + '.ts', import.meta.url)
    const source = readFileSync(path, 'utf8').replaceAll('import.meta.env', "({ PROD: false, VITE_API_URL: '' })")
    const code = ts.transpileModule(source, { compilerOptions: {
      module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, esModuleInterop: true
    } }).outputText
    const module = { exports: {} }
    runInNewContext(code, { ...context, exports: module.exports, module,
      require: (id) => id === 'axios' ? axios : load(id.split('/').at(-1)) }, { filename: path.pathname })
    modules[name] = module.exports
    return module.exports
  }
  const hooks = {}
  const instance = {
    interceptors: {
      request: { use: (fn) => { hooks.request = fn } },
      response: { use: (success, failure) => { hooks.success = success; hooks.failure = failure } }
    },
    request: async (config) => config
  }
  class CanceledError extends Error {}
  const axios = { create: () => instance, CanceledError, isAxiosError: (error) => !!error.isAxiosError,
    post: async () => { throw new Error('Unexpected refresh') }, delete: async () => ({}) }
  const headers = (data = {}) => new Map(Object.entries(data))
  return { load, hooks, axios, instance, headers, localStorage, sessionStorage }
}

function customerSession(env) {
  const customer = env.load('customerAuth')
  customer.saveCustomerSession('old-access', { id: 1, name: 'Cliente', establishment_id: 10 }, 'empresa', false, 30, 'old-csrf')
  return customer
}

test('staff logout clears all local credentials and ignores delayed token rotation', async () => {
  const env = environment(), staff = env.load('staffAuth')
  const api = env.load('api')
  staff.setStaffAccessToken('access')
  for (const store of [env.localStorage, env.sessionStorage]) {
    store.setItem('client', 'client'); store.setItem('uid', 'user'); store.setItem('user', '{}')
  }
  const request = await env.hooks.request({ url: '/me/sessions', headers: env.headers() })
  await api.logoutStaff()
  env.hooks.success({ config: request, headers: { 'access-token': 'late-access', client: 'client', uid: 'user' } })
  assert.equal(staff.getStaffAccessToken(), null)
  assert.equal(env.sessionStorage.getItem('client'), null)
  assert.equal(env.localStorage.getItem('user'), null)
})

test('Devise batch responses with blank access-token do not overwrite the valid token', async () => {
  const env = environment(), staff = env.load('staffAuth')
  env.load('api'); staff.setStaffAccessToken('valid-access')
  const config = await env.hooks.request({ url: '/me/sessions', headers: env.headers() })
  env.hooks.success({ config, headers: { 'access-token': ' ', client: 'client', uid: 'user' } })
  assert.equal(staff.getStaffAccessToken(), 'valid-access')
})

test('parallel customer requests share one refresh', async () => {
  const env = environment(), customer = customerSession(env)
  env.load('api')
  let finish, calls = 0
  env.axios.post = () => { calls++; return new Promise((resolve) => { finish = resolve }) }
  const first = env.hooks.request({ url: '/customer/profile', headers: env.headers() })
  const second = env.hooks.request({ url: '/customer/appointments', headers: env.headers() })
  assert.equal(calls, 1)
  finish({ data: { access_token: 'new-access', csrf_token: 'new-csrf', expires_in: 900 } })
  const requests = await Promise.all([first, second])
  assert.equal(customer.getCustomerToken(), 'new-access')
  for (const config of requests) assert.equal(config.headers.get('Authorization'), 'Bearer new-access')
})

test('refresh arriving after customer logout cannot resurrect session', async () => {
  const env = environment(), customer = customerSession(env), api = env.load('api')
  let finish
  env.axios.post = () => new Promise((resolve) => { finish = resolve })
  const pending = env.hooks.request({ url: '/customer/profile', headers: env.headers() })
  await api.logoutCustomer()
  finish({ data: { access_token: 'late-access', csrf_token: 'late-csrf', expires_in: 900 } })
  await assert.rejects(pending, env.axios.CanceledError)
  assert.equal(customer.getCustomerToken(), null)
  assert.equal(customer.getCustomerSlug(), null)
})

test('public login requests do not send credentials from an existing session', async () => {
  const env = environment(); customerSession(env); env.load('api')
  const config = await env.hooks.request({ url: '/customer_auth/outra/sign_in',
    headers: env.headers({ Authorization: 'Bearer old', 'access-token': 'old-staff', client: 'client', uid: 'user' }) })
  assert.equal(config.headers.size, 0)
})

test('a stale request cannot be retried under another customer session', async () => {
  const env = environment(), customer = customerSession(env)
  env.load('api')
  const oldVersion = customer.getCustomerSessionVersion()
  customer.saveCustomerSession('other-access', { id: 2, name: 'Outra Conta', establishment_id: 20 }, 'outra', false, 900, 'other-csrf')
  await assert.rejects(env.hooks.request({ url: '/customer/appointments', headers: env.headers(), _customerVersion: oldVersion }), env.axios.CanceledError)
})

test('updating customer profile preserves token expiry and CSRF', () => {
  const env = environment(), customer = customerSession(env)
  const expiry = env.sessionStorage.getItem('customer-token-expires')
  customer.updateCustomerData({ id: 1, name: 'Novo Nome', establishment_id: 10 })
  assert.equal(customer.getCustomerData().name, 'Novo Nome')
  assert.equal(customer.getCustomerCsrfToken(), 'old-csrf')
  assert.equal(env.sessionStorage.getItem('customer-token-expires'), expiry)
})

test('account deletion sends current password and clears session before redirect with the correct slug', async () => {
  const env = environment(), customer = customerSession(env), api = env.load('api')
  env.instance.delete = async (url, config) => {
    assert.equal(url, '/customer/profile')
    assert.equal(config.data.confirmation, 'cliente@example.test')
    assert.equal(config.data.current_password, ' Senha#ComEspacos ')
    return {}
  }
  const destination = await api.deleteCustomerAccount('cliente@example.test', ' Senha#ComEspacos ')
  assert.equal(destination, '/empresa/empresa')
  assert.equal(customer.getCustomerToken(), null)
  assert.equal(customer.getCustomerCsrfToken(), null)
  assert.equal(customer.getCustomerSlug(), null)
})

test('failed account deletion keeps the authenticated session', async () => {
  const env = environment(), customer = customerSession(env), api = env.load('api')
  env.instance.delete = async () => { throw new Error('Password rejected') }
  await assert.rejects(api.deleteCustomerAccount('cliente@example.test', 'errada'))
  assert.equal(customer.getCustomerToken(), 'old-access')
  assert.equal(customer.getCustomerCsrfToken(), 'old-csrf')
})

test('a delayed account deletion response cannot clear another account session', async () => {
  const env = environment(), customer = customerSession(env), api = env.load('api')
  let finish
  env.instance.delete = () => new Promise((resolve) => { finish = resolve })
  const pending = api.deleteCustomerAccount('cliente@example.test', 'senha')
  customer.saveCustomerSession('other-access', { id: 2, name: 'Outra Pessoa', establishment_id: 20 }, 'outra', false, 900, 'other-csrf')
  finish({})
  await assert.rejects(pending, env.axios.CanceledError)
  assert.equal(customer.getCustomerToken(), 'other-access')
  assert.equal(customer.getCustomerSlug(), 'outra')
})
