import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import { parse, compileScript } from '@vue/compiler-sfc'
import * as vue from 'vue'
import ts from 'typescript'

// Executa o script real da página. O carregamento é chamado explicitamente,
// sem montar o layout administrativo ou simular autorização pelo frontend.
async function page(apiDelete, confirm) {
  const source = readFileSync(new URL('../src/views/super-admin/PlansPage/SuperAdminPlansPage.vue', import.meta.url), 'utf8')
  const { descriptor } = parse(source)
  const script = compileScript(descriptor, { id: 'plan-deletion-test' })
  const code = ts.transpileModule(script.content, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022
  } }).outputText
  const module = { exports: {} }
  const api = { delete: apiDelete, get: async () => ({ data: [
    { id: 1, name: 'Inicial', active: true, max_owner_sessions: 1 },
    { id: 2, name: 'Superior', active: true, max_owner_sessions: 4 }
  ] }) }
  runInNewContext(code, { module, exports: module.exports, window: { confirm },
    require: id => id === 'vue' ? { ...vue, onMounted() {} }
      : id === '@/services/api' ? { api } : {} })
  const state = module.exports.default.setup({}, { expose() {} })
  await state.loadPlans()
  return state
}

test('canceling plan deletion preserves the catalog and never calls the API', async () => {
  let calls = 0
  const state = await page(async () => { calls++ }, () => false)
  await state.deletePlan(state.plans.value[1])
  assert.equal(calls, 0)
  assert.equal(state.plans.value.length, 2)
  assert.equal(state.deletingPlanId.value, null)
  assert.equal(state.catalogFull.value, true)
})

test('deletion waits for server approval blocks duplicate actions and releases the highest tier on success', async () => {
  let finish, calls = 0
  const state = await page(path => {
    assert.equal(path, '/super_admin/plans/2')
    calls++
    return new Promise(resolve => { finish = resolve })
  }, message => { assert.match(message, /Superior/); return true })
  const plan = state.plans.value[1]
  const pending = state.deletePlan(plan)
  assert.equal(state.deletingPlanId.value, 2)
  assert.equal(state.plans.value.length, 2)
  await state.deletePlan(plan)
  state.openEditModal(plan)
  state.openCreateModal()
  assert.equal(calls, 1)
  assert.equal(state.showModal.value, false)
  finish()
  await pending
  assert.equal(state.plans.value.length, 1)
  assert.equal(state.plans.value[0].id, 1)
  assert.equal(state.activePlanCount.value, 1)
  assert.equal(state.catalogFull.value, false)
  assert.equal(state.deletingPlanId.value, null)
  assert.equal(state.successMessage.value, 'Plano excluído com sucesso.')
})

test('subscription conflicts preserve the row show safe feedback and allow retry', async () => {
  let attempts = 0
  const state = await page(async () => {
    if (++attempts === 1) throw { response: { status: 409, data: {
      code: 'PLAN_HAS_SUBSCRIPTIONS', error: 'Plano com assinaturas. Desative o plano.'
    } } }
  }, () => true)
  const plan = state.plans.value[1]
  await state.deletePlan(plan)
  assert.equal(state.plans.value.length, 2)
  assert.equal(state.deletingPlanId.value, null)
  assert.equal(state.errorMessage.value, 'Plano com assinaturas. Desative o plano.')
  assert.equal(state.successMessage.value, '')
  await state.deletePlan(plan)
  assert.equal(attempts, 2)
  assert.equal(state.errorMessage.value, '')
  assert.equal(state.plans.value.length, 1)
})
