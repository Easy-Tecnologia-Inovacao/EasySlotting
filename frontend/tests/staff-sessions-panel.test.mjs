import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import { parse, compileScript } from '@vue/compiler-sfc'
import * as vue from 'vue'
import ts from 'typescript'

const row = (id, current = false) => ({ client_id: id, is_current: current, device: 'Windows · Chrome',
  ip: '127.0.0.1', last_seen_at: null, expires_at: '2026-10-10T14:00:00Z' })
const inventory = (rows = [row('current', true), row('other')]) => ({ sessions: rows, limit: 5, active_count: rows.length })
function page(api, { confirm = () => true, logout } = {}) {
  const source = readFileSync(new URL('../src/components/StaffSessionsPanel.vue', import.meta.url), 'utf8')
  const { descriptor } = parse(source)
  const script = compileScript(descriptor, { id: 'staff-sessions-test' })
  const code = ts.transpileModule(script.content, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022
  } }).outputText
  const module = { exports: {} }
  let unmount, version = 0
  const redirects = []
  runInNewContext(code, { module, exports: module.exports, window: { confirm },
    require: id => id === 'vue' ? { ...vue, onMounted() {}, onBeforeUnmount(fn) { unmount = fn } }
      : id === 'vue-router' ? { useRouter: () => ({ replace: async path => { redirects.push(path) } }) }
      : id === '@/services/api' ? { api, logoutStaff: async () => { version++; await logout?.() } }
      : id === '@/services/staffAuth' ? { getStaffSessionVersion: () => version } : {} })
  const state = module.exports.default.setup({}, { expose() {} })
  return { state, redirects, unmount: () => unmount(), changeAccount: () => { version++ } }
}

test('failed or incompatible loads hide inventory block actions and allow a successful retry', async () => {
  let response = inventory(), deletes = 0, confirms = 0
  const { state } = page({ get: async () => {
    if (response === null) throw new Error('private details')
    return { data: response }
  }, delete: async () => { deletes++ } }, { confirm: () => { confirms++; return true } })
  assert.equal(state.limit.value, null)
  assert.equal(state.hasLoaded.value, false)
  await state.loadSessions()
  assert.equal(state.limit.value, 5)
  for (const invalid of [null, { sessions: {}, limit: 5, active_count: 0 },
    { ...inventory(), active_count: 9 }, { ...inventory(), limit: '5' },
    inventory([row('same', true), row('same')]), inventory([row('bad!id', true)]),
    inventory([{ ...row('current', true), expires_at: 'invalid' }])]) {
    response = invalid
    await state.loadSessions()
    assert.equal(state.hasLoaded.value, false)
    assert.equal(state.sessions.value.length, 0)
    assert.equal(state.limit.value, null)
    assert.doesNotMatch(state.errorMessage.value, /private/)
    await state.revokeSession(row('other'))
    await state.revokeOthers()
  }
  assert.equal(confirms, 0)
  assert.equal(deletes, 0)
  response = inventory([])
  await state.loadSessions()
  assert.equal(state.hasLoaded.value, true)
  assert.equal(state.errorMessage.value, '')
})

test('in flight loads reject duplicate loads and mutations before confirmation', async () => {
  let finish, gets = 0, deletes = 0, confirms = 0
  const { state } = page({ get: () => { gets++; return new Promise(resolve => { finish = resolve }) },
    delete: async () => { deletes++ } }, { confirm: () => { confirms++; return true } })
  const pending = state.loadSessions()
  await state.loadSessions()
  await state.revokeSession(row('other'))
  await state.revokeOthers()
  assert.equal(gets, 1)
  assert.equal(deletes, 0)
  assert.equal(confirms, 0)
  finish({ data: inventory() })
  await pending
  assert.equal(state.hasLoaded.value, true)
})

test('revocation serializes updates and only the post delete inventory becomes usable', async () => {
  let finish, gets = 0, deletes = 0
  const { state } = page({ get: async () => ({ data: ++gets === 1 ? inventory() : inventory([row('current', true)]) }),
    delete: () => { deletes++; return new Promise(resolve => { finish = resolve }) } })
  await state.loadSessions()
  const pending = state.revokeSession(row('other'))
  await state.loadSessions()
  await state.revokeOthers()
  await state.revokeSession(row('other'))
  assert.equal(gets, 1)
  assert.equal(deletes, 1)
  finish()
  await pending
  assert.equal(gets, 2)
  assert.equal(state.sessions.value.length, 1)
  assert.equal(state.sessions.value[0].client_id, 'current')
  assert.equal(state.busy.value, false)
})

test('uncertain deletion clears inventory until retry and cancellation sends nothing', async () => {
  let confirms = false, deletes = 0
  const { state } = page({ get: async () => ({ data: inventory() }), delete: async () => { deletes++; throw new Error('offline') } },
    { confirm: () => confirms })
  await state.loadSessions()
  await state.revokeSession(row('other'))
  assert.equal(deletes, 0)
  assert.equal(state.hasLoaded.value, true)
  confirms = true
  await state.revokeOthers()
  assert.equal(deletes, 1)
  assert.equal(state.hasLoaded.value, false)
  assert.equal(state.successMessage.value, '')
  await state.loadSessions()
  assert.equal(state.hasLoaded.value, true)
})

test('responses after account change or unmount cannot populate the old panel', async () => {
  for (const finishLifecycle of ['changeAccount', 'unmount']) {
    let finish
    const view = page({ get: () => new Promise(resolve => { finish = resolve }) })
    const pending = view.state.loadSessions()
    view[finishLifecycle]()
    finish({ data: inventory() })
    await pending
    assert.equal(view.state.sessions.value.length, 0)
    assert.equal(view.state.hasLoaded.value, false)
  }
})

test('current session logout clears identity before failure and still redirects safely', async () => {
  const view = page({ get: async () => ({ data: inventory() }) }, { logout: async () => { throw new Error('offline') } })
  await view.state.loadSessions()
  // A flag supplied to the handler cannot replace the actual inventory entry.
  await view.state.revokeSession({ ...row('current'), is_current: false })
  assert.deepEqual(view.redirects, ['/sistema/login'])
})
