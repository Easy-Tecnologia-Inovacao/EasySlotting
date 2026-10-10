import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import { createRequire } from 'node:module'
const require = createRequire(new URL('../package.json', import.meta.url))
const { parse, compileScript } = require('@vue/compiler-sfc')
const vue = require('vue'), ts = require('typescript')
function page(api, captured = []) {
  const source = readFileSync(new URL('../src/views/super-admin/SecurityLogsPage/SuperAdminSecurityLogsPage.vue', import.meta.url), 'utf8')
  const script = compileScript(parse(source).descriptor, { id: 'review' })
  const code = ts.transpileModule(script.content, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText
  let dispose; const module = { exports: {} }
  runInNewContext(code, { module, exports: module.exports, console: { error: (...args) => captured.push(args) }, require: id => id === 'vue' ? { ...vue, onMounted() {}, onBeforeUnmount(callback) { dispose = callback } } : id === '@/services/api' ? { api } : {} })
  const state = module.exports.default.setup({}, { expose() {} }); state.dispose = () => dispose(); return state
}
const response = id => ({ data: { logs: [{ id, action: "login" }], pagination: { total_count: 1, total_pages: 1 } } })
test('failed request shows error without logging credentials', async () => {
  const error = { config: { headers: { 'access-token': 'SYNTHETIC' } } }, captured = []
  const state = page({ get: async () => { throw error } }, captured)
  await state.fetchLogs()
  assert.equal(state.loading.value, false)
  assert.equal(state.logs.value.length, 0)
  assert.equal(captured.length, 0)
  assert.ok(state.logsError.value)
  assert.equal(state.totalLogs.value, null)
})
test('old response cannot overwrite newer response', async () => {
  const pending = [], state = page({ get: () => new Promise(resolve => pending.push(resolve)) })
  const first = state.fetchLogs(), second = state.fetchLogs()
  pending[1](response(2)); await second
  pending[0](response(1)); await first
  assert.equal(state.logs.value[0].id, 2)
})
test('filtering resets current page', async () => {
  let params
  const state = page({ get: async (_, config) => { params = config.params; return response(1) } })
  state.currentPage.value = 5
  state.filters.value.action_type = 'login_failed'
  await state.applyFilters()
  assert.equal(params.page, 1)
  assert.equal(params.action_type, 'login_failed')
})

test('failed or malformed summary remains unknown and can retry', async () => {
  let data = {}
  const state = page({ get: async () => ({ data }) })
  await state.fetchSummary()
  assert.ok(state.summaryError.value)
  assert.equal(state.summary.value.logins_24h, undefined)
  data = { generated_at: '2026-10-10T12:00:00Z', summary: { logins_24h: 0, failed_logins_24h: 0, suspicious_ip_count: 0 } }
  await state.fetchSummary()
  assert.equal(state.summaryError.value, '')
  assert.equal(state.summary.value.logins_24h, 0)
})

test('malformed list clears old data and permits retry', async () => {
  let result = response(1)
  const state = page({ get: async () => result })
  await state.fetchLogs()
  assert.equal(state.logs.value.length, 1)
  result = { data: { logs: [null] } }
  await state.fetchLogs()
  assert.ok(state.logsError.value)
  assert.equal(state.logs.value.length, 0)
  result = response(2)
  await state.fetchLogs()
  assert.equal(state.logsError.value, '')
  assert.equal(state.logs.value[0].id, 2)
})

test('unmount ignores pending private responses', async () => {
  const pending = [], state = page({ get: () => new Promise(resolve => pending.push(resolve)) })
  const request = state.fetchLogs()
  state.dispose()
  pending[0](response(1))
  await request
  assert.equal(state.logs.value.length, 0)
})

test('dedicated options support search and preserve selection', async () => {
  let request, data = { establishments: [{ id: 1, name: 'Empresa' }], actions: [{ value: 'password_change', label: 'Senha' }], has_more: true }
  const state = page({ get: async (url, config) => { request = { url, config }; return { data } } })
  await state.fetchEstablishments()
  assert.equal(request.url, '/super_admin/audit_logs/filter_options')
  assert.equal(state.hasMoreEstablishments.value, true)
  state.filters.value.establishment_id = 1
  state.establishmentQuery.value = 'Outra'
  data = { ...data, establishments: [{ id: 2, name: 'Outra' }] }
  await state.fetchEstablishments()
  assert.equal(request.config.params.q, 'Outra')
  assert.equal(state.establishments.value[0].id, 1)
  assert.equal(state.getActionLabel('password_changed'), 'Senha')
})
