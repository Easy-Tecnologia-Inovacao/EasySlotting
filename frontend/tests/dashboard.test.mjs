import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import { parse, compileScript } from '@vue/compiler-sfc'
import * as vue from 'vue'
import ts from 'typescript'

const payload = () => ({
  generated_at: '2026-10-01T00:00:00-03:00',
  summary: { monthly_contracted_value: 50, active_subscriptions_count: 1 },
  charts: { subscriptions_by_plan: [{ name: 'Plano', total: 1 }], cancellation_reasons: [],
    contracted_value_trend: [{ month: '10/2026', value: 50 }] },
  recent_cancellations: []
})

function page(get) {
  const source = readFileSync(new URL('../src/views/super-admin/DashboardPage/SuperAdminDashboardPage.vue', import.meta.url), 'utf8')
  const script = compileScript(parse(source).descriptor, { id: 'dashboard-test' })
  const code = ts.transpileModule(script.content, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022
  } }).outputText
  const module = { exports: {} }
  const logs = []
  runInNewContext(code, { module, exports: module.exports,
    console: { error: (...args) => logs.push(args), log: (...args) => logs.push(args) },
    require: id => id === 'vue' ? { ...vue, onMounted() {} }
      : id === '@/services/api' ? { api: { get } }
      : id === 'chart.js' ? { Chart: { register() {} } } : {} })
  return { state: module.exports.default.setup({}, { expose() {} }), logs }
}

test('dashboard uses server generation time and contracted values only after successful load', async () => {
  const { state } = page(async url => {
    assert.equal(url, '/super_admin/dashboard')
    return { data: payload() }
  })
  assert.equal(state.hasLoaded.value, false)
  assert.equal(state.generatedAt.value, null)
  await state.loadDashboard()
  assert.equal(state.hasLoaded.value, true)
  assert.equal(state.errorMessage.value, '')
  assert.equal(state.generatedAt.value, payload().generated_at)
  assert.equal(state.summary.value.monthly_contracted_value, 50)
  assert.equal(state.revenueTrendData.value.datasets[0].data[0], 50)
})

test('failed reload hides stale metrics clears timestamp and never logs raw credentials then retries', async () => {
  let calls = 0
  const { state, logs } = page(async () => {
    if (++calls === 2) throw { config: { headers: { 'access-token': 'TEST_SENTINEL' } },
      response: { status: 500, data: { error: 'Detalhes internos privados' } } }
    return { data: payload() }
  })
  await state.loadDashboard()
  await state.loadDashboard()
  assert.equal(state.hasLoaded.value, false)
  assert.equal(state.generatedAt.value, null)
  assert.equal(state.loading.value, false)
  assert.match(state.errorMessage.value, /Não foi possível/)
  assert.doesNotMatch(state.errorMessage.value, /privados|SENTINEL/)
  assert.equal(logs.length, 0)
  await state.loadDashboard()
  assert.equal(state.hasLoaded.value, true)
  assert.equal(state.errorMessage.value, '')
})

test('rate limit and incompatible API responses never become successful empty dashboards', async () => {
  let calls = 0
  const { state } = page(async () => {
    if (++calls === 1) throw { response: { status: 429 } }
    return { data: {} }
  })
  await state.loadDashboard()
  assert.match(state.errorMessage.value, /Aguarde um minuto/)
  assert.equal(state.hasLoaded.value, false)
  await state.loadDashboard()
  assert.match(state.errorMessage.value, /Não foi possível/)
  assert.equal(state.hasLoaded.value, false)
  assert.equal(state.generatedAt.value, null)
})

test('repeated load attempts share pending state instead of issuing concurrent requests', async () => {
  let finish, calls = 0
  const { state } = page(() => {
    calls++
    return new Promise(resolve => { finish = resolve })
  })
  const pending = state.loadDashboard()
  await state.loadDashboard()
  assert.equal(calls, 1)
  assert.equal(state.loading.value, true)
  finish({ data: payload() })
  await pending
  assert.equal(state.loading.value, false)
  assert.equal(state.hasLoaded.value, true)
})
