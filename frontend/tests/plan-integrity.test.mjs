import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import { parse, compileScript } from '@vue/compiler-sfc'
import * as vue from 'vue'
import ts from 'typescript'

function page(api) {
  const source = readFileSync(new URL('../src/views/super-admin/PlansPage/SuperAdminPlansPage.vue', import.meta.url), 'utf8')
  const { descriptor } = parse(source)
  const script = compileScript(descriptor, { id: 'plan-integrity-test' })
  const code = ts.transpileModule(script.content, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022
  } }).outputText
  const module = { exports: {} }
  runInNewContext(code, { module, exports: module.exports, window: { confirm: () => true },
    require: id => id === 'vue' ? { ...vue, onMounted() {} }
      : id === '@/services/api' ? { api } : {} })
  return module.exports.default.setup({}, { expose() {} })
}

test('failed and malformed catalog loads block mutations until a successful retry', async () => {
  let result = 'failure', mutations = 0
  const state = page({ get: async () => {
    if (result === 'failure') throw new Error('internal database details')
    return { data: result === 'malformed' ? {} : [] }
  }, post: async () => { mutations++ }, delete: async () => { mutations++ } })
  for (const value of ['failure', 'malformed']) {
    result = value
    await state.loadPlans()
    assert.equal(state.hasLoaded.value, false)
    assert.doesNotMatch(state.errorMessage.value, /database/)
    state.openCreateModal()
    state.openEditModal({ id: 1 })
    await state.savePlan()
    await state.deletePlan({ id: 1 })
    assert.equal(state.showModal.value, false)
    assert.equal(mutations, 0)
  }
  result = 'success'
  await state.loadPlans()
  assert.equal(state.hasLoaded.value, true)
  state.openCreateModal()
  assert.equal(state.showModal.value, true)
})

test('fractional and overflowing limits are rejected without truncation or API mutation', async () => {
  let calls = 0
  const state = page({ get: async () => ({ data: [] }), post: async () => { calls++ } })
  await state.loadPlans()
  state.openCreateModal()
  Object.assign(state.form.value, { name: 'Inicial', code: 'inicial', price: 100 })
  for (const field of ['duration_months', 'max_employees', 'max_services', 'max_appointments_per_month']) {
    const original = state.form.value[field]
    state.form.value[field] = '1.5'
    await state.savePlan()
    assert.ok(state.validationErrors.value.length > 0)
    state.form.value[field] = original
  }
  state.form.value.max_services = 2147483648
  await state.savePlan()
  assert.ok(state.validationErrors.value.length > 0)
  assert.equal(calls, 0)
})

test('promotion edits send only the selected discount source and preserve the local instant as ISO', async () => {
  let payload
  const state = page({ get: async () => ({ data: [] }), put: async (_path, data) => { payload = data.plan } })
  await state.loadPlans()
  state.openEditModal({ id: 1, name: 'Inicial', code: 'inicial', price: 100, duration_months: 1,
    active: true, max_owner_sessions: 1, promotion_active: true, promotional_price: 80,
    discount_percentage: 20, promotion_starts_at: '2026-10-10T15:00:00Z', promotion_duration_days: 3 })
  Object.assign(state.form.value, { promotion_mode: 'percentage', discount_percentage: 50, promotion_starts_at: '2026-10-10T12:00' })
  await state.savePlan()
  assert.equal(payload.discount_percentage, 50)
  assert.equal(payload.promotional_price, null)
  assert.equal(payload.promotion_mode, 'percentage')
  assert.equal(payload.promotion_starts_at, new Date('2026-10-10T12:00').toISOString())
})

test('zero promotional price is valid and scheduled or expired promotions have distinct labels', async () => {
  let payload
  const state = page({ get: async () => ({ data: [] }), post: async (_path, data) => { payload = data.plan } })
  await state.loadPlans()
  state.openCreateModal()
  Object.assign(state.form.value, { name: 'Inicial', code: 'inicial', price: 100, promotion_active: true,
    promotion_mode: 'price', promotional_price: 0, promotion_starts_at: '2026-10-10T12:00', promotion_duration_days: 1 })
  await state.savePlan()
  assert.equal(payload.promotional_price, 0)
  assert.equal(payload.discount_percentage, null)
  const future = new Date(Date.now() + 86400000).toISOString()
  const past = new Date(Date.now() - 86400000).toISOString()
  assert.equal(state.promotionLabel({ promotion_active: true, promotion_starts_at: future, promotion_ends_at: future }), 'Agendada')
  assert.equal(state.promotionLabel({ promotion_active: true, promotion_starts_at: past, promotion_ends_at: past }), 'Encerrada')
})
