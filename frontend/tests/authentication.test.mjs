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

function environment({ hostname = 'localhost', apiURL = '', production = false } = {}) {
  const localStorage = storage(), sessionStorage = storage()
  const modules = {}
  const context = { localStorage, sessionStorage, Date, crypto: globalThis.crypto,
    window: { location: { hostname, protocol: 'http:', assign: () => {} } } }
  function load(name) {
    if (modules[name]) return modules[name]
    const path = new URL(name === 'router' ? '../src/router/index.ts' :
      '../src/services/' + name + '.ts', import.meta.url)
    const source = readFileSync(path, 'utf8').replaceAll('import.meta.env',
      '(' + JSON.stringify({ PROD: production, VITE_API_URL: apiURL, BASE_URL: '/' }) + ')')
    const code = ts.transpileModule(source, { compilerOptions: {
      module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, esModuleInterop: true
    } }).outputText
    const module = { exports: {} }
    runInNewContext(code, { ...context, exports: module.exports, module,
      require: (id) => {
        if (id === 'axios') return axios
        if (id.endsWith('.vue')) return {}
        if (id === 'vue-router') return {
          createWebHistory: () => ({}),
          createRouter: () => ({ beforeEach(guard) { this.guard = guard } })
        }
        return load(id.split('/').at(-1))
      } }, { filename: path.pathname })
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
  const axios = { create: (config) => { instance.defaults = config; return instance },
    CanceledError, isAxiosError: (error) => !!error.isAxiosError,
    post: async () => { throw new Error('Unexpected refresh') }, delete: async () => ({}) }
  const headers = (data = {}) => new Map(Object.entries(data))
  return { load, reload: (name) => { delete modules[name]; return load(name) },
    hooks, axios, instance, headers, localStorage, sessionStorage }
}

function customerSession(env) {
  const customer = env.load('customerAuth')
  customer.saveCustomerSession('old-access', { id: 1, name: 'Cliente', establishment_id: 10 }, 'empresa', false, 30, 'old-csrf')
  return customer
}

function persistedStaff(env) {
  env.load('staffAuth').saveStaffSession('old-access', 'client', 'owner@example.test',
    { id: 1, role: 'owner' }, 'csrf')
  // F5 recarrega o módulo, mas preserva sessionStorage da mesma aba.
  return env.reload('staffAuth')
}

function restoredStaffResponse(role = 'owner') {
  return { headers: { 'access-token': 'restored-access', client: 'client', uid: 'owner@example.test' },
    data: { data: { id: 1, role, name: 'Conta validada' } } }
}

test('LAN development keeps login restore and logout same-origin despite legacy localhost API configuration', async () => {
  const env = environment({ hostname: '172.16.0.2', apiURL: 'http://localhost:3000/api' })
  persistedStaff(env)
  const api = env.load('api')
  assert.equal(env.instance.defaults.baseURL, '/api')
  env.axios.post = async (url, body, config) => {
    assert.equal(url, '/api/devise_users/restore_session')
    assert.equal(config.withCredentials, true)
    return restoredStaffResponse()
  }
  assert.equal(await api.restoreStaffSession(), true)
  env.axios.delete = async url => { assert.equal(url, '/api/devise_users/sign_out') }
  await api.logoutStaff()
})

test('customer refresh also uses the same-origin API in LAN development', async () => {
  const env = environment({ hostname: '172.16.0.2', apiURL: 'http://localhost:3000/api' })
  customerSession(env)
  env.load('api')
  env.axios.post = async (url, body, config) => {
    assert.equal(url, '/api/customer_auth/empresa/refresh')
    assert.equal(config.withCredentials, true)
    return { data: { access_token: 'refreshed', csrf_token: 'new-csrf', expires_in: 900 } }
  }
  const request = await env.hooks.request({ url: '/customer/profile', headers: env.headers() })
  assert.equal(request.headers.get('Authorization'), 'Bearer refreshed')
})

test('production preserves explicitly configured API URLs and the relative default', () => {
  for (const apiURL of ['', '/api', 'https://api.example.test/api']) {
    const env = environment({ production: true, apiURL })
    env.load('api')
    assert.equal(env.instance.defaults.baseURL, apiURL || '/api')
  }
})

test('F5 restores every staff role from the server without persisting an access token', async () => {
  for (const role of ['owner', 'employee', 'super_admin']) {
    const env = environment(), staff = persistedStaff(env), api = env.load('api')
    assert.equal(staff.getStaffAccessToken(), null)
    env.axios.post = async (url, body, config) => {
      assert.match(url, /\/devise_users\/restore_session$/)
      assert.equal(config.withCredentials, true)
      assert.equal(config.headers['X-CSRF-Token'], 'csrf')
      assert.equal(config.headers['X-Staff-Uid'], 'owner@example.test')
      assert.equal(config.headers['X-Staff-Client'], 'client')
      assert.equal(config.headers['access-token'], undefined)
      return restoredStaffResponse(role)
    }
    assert.equal(await api.restoreStaffSession(), true)
    assert.equal(staff.getStaffAccessToken(), 'restored-access')
    assert.equal(JSON.parse(env.sessionStorage.getItem('user')).role, role)
    assert.equal(env.sessionStorage.getItem('access-token'), null)
    assert.equal(env.localStorage.getItem('access-token'), null)
  }
})

test('home navigation waits for F5 recovery and keeps every validated staff role on the landing page', async () => {
  for (const [role, dashboard] of [['owner', '/admin/estabelecimento'],
      ['employee', '/admin/agendamentos'], ['super_admin', '/super-admin/dashboard']]) {
    const env = environment(), staff = persistedStaff(env)
    const router = env.load('router').default
    let finish, completed = false
    env.axios.post = () => new Promise(resolve => { finish = resolve })
    const navigation = router.guard({ path: '/', params: {} }).then(result => {
      completed = true
      return result
    })
    await Promise.resolve()
    assert.equal(completed, false)
    assert.equal(staff.getStaffAccessToken(), null)
    finish(restoredStaffResponse(role))
    assert.equal(await navigation, true)
    assert.equal(staff.getStaffAccessToken(), 'restored-access')
    assert.equal(JSON.parse(env.sessionStorage.getItem('user')).role, role)
    assert.equal(await router.guard({ path: '/sistema/login', params: {} }), dashboard)
    await env.load('api').logoutStaff()
    assert.equal(await router.guard({ path: '/', params: {} }), true)
    assert.equal(staff.getStaffAccessToken(), null)
  }
})

test('home stays public without authenticating visitors or invalid sessions from stored metadata', async () => {
  for (const scenario of ['visitor', 'forged-profile', 'revoked', 'network-error']) {
    const env = environment()
    if (['revoked', 'network-error'].includes(scenario)) persistedStaff(env)
    if (scenario === 'forged-profile') env.sessionStorage.setItem('user', JSON.stringify({ role: 'super_admin' }))
    let calls = 0
    env.axios.post = async () => {
      calls++
      throw { isAxiosError: true, response: { status: scenario === 'revoked' ? 401 : 500 } }
    }
    const router = env.load('router').default
    assert.equal(await router.guard({ path: '/', params: {} }), true)
    assert.equal(env.load('staffAuth').getStaffAccessToken(), null)
    assert.equal(calls, ['revoked', 'network-error'].includes(scenario) ? 1 : 0)
    assert.equal(env.sessionStorage.getItem('staff-csrf-token'), scenario === 'network-error' ? 'csrf' : null)
  }
})

test('parallel restoration attempts share a single request', async () => {
  const env = environment(); persistedStaff(env)
  const api = env.load('api')
  let calls = 0, finish
  env.axios.post = () => { calls++; return new Promise(resolve => { finish = resolve }) }
  const first = api.restoreStaffSession(), second = api.restoreStaffSession()
  assert.equal(calls, 1)
  finish(restoredStaffResponse())
  assert.deepEqual(await Promise.all([first, second]), [true, true])
})

test('delayed restoration cannot resurrect logout or overwrite a new login', async () => {
  for (const newLogin of [false, true]) {
    const env = environment(), staff = persistedStaff(env), api = env.load('api')
    let finish
    env.axios.post = () => new Promise(resolve => { finish = resolve })
    const pending = api.restoreStaffSession()
    await api.logoutStaff()
    if (newLogin) staff.saveStaffSession('new-account-token', 'other-client', 'other@example.test',
      { id: 2, role: 'owner' }, 'other-csrf')
    finish(restoredStaffResponse())
    await assert.rejects(pending, env.axios.CanceledError)
    assert.equal(staff.getStaffAccessToken(), newLogin ? 'new-account-token' : null)
    assert.equal(staff.getStaffCsrfToken(), newLogin ? 'other-csrf' : null)
  }
})

test('invalid or revoked recovery clears local references while network failure permits retry', async () => {
  for (const status of [401, 403, 500, undefined]) {
    const env = environment(), staff = persistedStaff(env), api = env.load('api')
    const error = { isAxiosError: true, response: status ? { status } : undefined }
    env.axios.post = async () => { throw error }
    await assert.rejects(api.restoreStaffSession(), value => value === error)
    assert.equal(staff.getStaffAccessToken(), null)
    assert.equal(staff.getStaffCsrfToken(), [401, 403].includes(status) ? null : 'csrf')
  }
})

test('restoration rejects a response belonging to another cookie identity', async () => {
  const env = environment(), staff = persistedStaff(env), api = env.load('api')
  const response = restoredStaffResponse()
  response.headers.uid = 'other@example.test'
  env.axios.post = async () => response
  assert.equal(await api.restoreStaffSession(), false)
  assert.equal(staff.getStaffAccessToken(), null)
  assert.equal(staff.getStaffCsrfToken(), null)
})

test('logout forwards recovery proof even when F5 has erased the memory token', async () => {
  const env = environment(), staff = persistedStaff(env), api = env.load('api')
  env.axios.delete = async (url, config) => {
    assert.equal(config.headers['X-CSRF-Token'], 'csrf')
    assert.equal(config.headers.client, 'client')
    assert.equal(config.headers['access-token'], '')
    assert.equal(staff.getStaffCsrfToken(), null)
    return {}
  }
  await api.logoutStaff()
  assert.equal(await api.restoreStaffSession(), false)
})

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
