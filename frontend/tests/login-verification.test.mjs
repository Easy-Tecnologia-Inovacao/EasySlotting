import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'
import { parse, compileScript } from '@vue/compiler-sfc'
import * as vue from 'vue'
import ts from 'typescript'

// Exercita os scripts reais dos SFCs, reatividade e lifecycle Vue, sem browser.
function mountScript(path, props = vue.reactive({}), imports = {}) {
  const filename = new URL('../src/' + path, import.meta.url)
  const { descriptor } = parse(readFileSync(filename, 'utf8'), { filename: filename.pathname })
  const script = compileScript(descriptor, { id: 'login-verification-test' })
  const code = ts.transpileModule(script.content, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, esModuleInterop: true
  } }).outputText
  const values = new Map(), timers = new Map(), events = []
  const storage = { getItem: key => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, String(value)), removeItem: key => values.delete(key) }
  let nextTimer = 0
  const module = { exports: {} }
  runInNewContext(code, { module, exports: module.exports, console, Date,
    localStorage: storage, sessionStorage: storage,
    document: { documentElement: { setAttribute() {} } },
    setInterval: callback => { const id = ++nextTimer; timers.set(id, callback); return id },
    clearInterval: id => timers.delete(id), setTimeout: () => ++nextTimer,
    require: id => id === 'vue' ? vue : imports[id] || {} })
  let state
  const renderer = vue.createRenderer({
    createComment: () => ({}), createText: () => ({}), createElement: () => ({}),
    insert() {}, remove() {}, setText() {}, setElementText() {}, patchProp() {},
    parentNode: () => null, nextSibling: () => null
  })
  const app = renderer.createApp({ setup() {
    state = module.exports.default.setup(props, { expose() {}, emit: (...args) => events.push(args) })
    return () => null
  } })
  app.mount({})
  return { state, events, timers, unmount: () => app.unmount() }
}

test('email verification accepts a retry after failure and blocks duplicate or malformed submissions', async () => {
  const props = vue.reactive({ show: false, emailMasked: 'p***@example.test', loading: false, resending: false })
  const modal = mountScript('components/LoginVerificationModal.vue', props)
  try {
    props.show = true
    await vue.nextTick()
    modal.state.otpCode.value = 'abcdef'
    modal.state.submitVerification()
    assert.equal(modal.events.length, 0)
    modal.state.otpCode.value = '123456'
    modal.state.submitVerification()
    props.loading = true
    modal.state.submitVerification()
    assert.equal(modal.events.length, 1)
    props.loading = false
    props.errorMsg = 'Código inválido'
    modal.state.otpCode.value = '654321'
    modal.state.submitVerification()
    assert.deepEqual(modal.events, [['verify', '123456'], ['verify', '654321']])
  } finally { modal.unmount() }
})

test('email resend observes cooldown and request state and cleans up timers', async () => {
  const props = vue.reactive({ show: false, emailMasked: 'p***@example.test', loading: false, resending: false })
  const modal = mountScript('components/LoginVerificationModal.vue', props)
  props.show = true
  await vue.nextTick()
  assert.equal(modal.state.resendCooldown.value, 60)
  modal.state.resendCode()
  assert.equal(modal.events.length, 0)
  for (let second = 0; second < 60; second++) for (const tick of [...modal.timers.values()]) tick()
  props.loading = true
  modal.state.resendCode()
  props.loading = false
  props.resending = true
  modal.state.resendCode()
  assert.equal(modal.events.length, 0)
  props.resending = false
  modal.state.resendCode()
  assert.deepEqual(modal.events, [['resend']])
  assert.equal(modal.timers.size, 1)
  modal.unmount()
  assert.equal(modal.timers.size, 0)
})

test('staff and customer login views wait for the email code before saving a session and allow retry', async () => {
  for (const role of ['owner', 'employee', 'super_admin', 'customer']) {
    const customer = role === 'customer', saved = [], requests = []
    const api = { post: async (path, payload) => {
      requests.push({ path, payload })
      if (!payload.otp_code) return { data: { requires_verification: true, email_masked: 'p***@example.test' } }
      if (payload.otp_code !== '654321') throw { response: { status: 401,
        data: { error: 'Código inválido', errors: ['Código inválido'] } } }
      return customer ? { data: { access_token: 'jwt', csrf_token: 'csrf', expires_in: 900, customer: { id: 1 } } }
        : { headers: { 'access-token': 'access', client: 'client', uid: 'person@example.test' },
          data: { data: { id: 1, role }, staff_csrf_token: 'csrf' } }
    } }
    const imports = {
      'vue-router': { useRouter: () => ({ push() {} }), useRoute: () => ({ params: { slug: 'empresa' }, query: {} }) },
      '@/services/api': { api, getOrCreateDeviceToken: () => 'a'.repeat(64) },
      '@/services/staffAuth': { clearStaffAccessToken() {}, saveStaffSession: (...args) => saved.push(args) },
      '@/services/customerAuth': { clearCustomerSession() {}, saveCustomerSession: (...args) => saved.push(args) },
      '@/stores/themeStore': { useThemeStore: () => ({ salonConfig: { nome: 'Empresa' } }) }
    }
    const page = mountScript(customer ? 'views/public/LoginPage/CustomerLoginPage.vue'
      : 'views/landing/LoginPage/LoginPage.vue', undefined, imports)
    try {
      page.state.form.email = 'person@example.test'
      page.state.form.password = 'TesteSeguro#2026'
      await page.state.handleLogin()
      assert.equal(page.state.showVerificationModal.value, true)
      assert.equal(saved.length, 0)
      await page.state.handleVerifyOtp('123456')
      assert.equal(page.state.loading.value, false)
      assert.equal(page.state.verificationError.value, 'Código inválido')
      assert.equal(saved.length, 0)
      await page.state.handleVerifyOtp('654321')
      assert.equal(page.state.showVerificationModal.value, false)
      assert.equal(saved.length, 1)
      assert.equal(requests.at(-1).payload.device_token, 'a'.repeat(64))
      assert.equal(requests.at(-1).path, customer ? '/customer_auth/empresa/sign_in' : '/devise_users/sign_in')
      // Um reenvio malsucedido não deixa o formulário preso em carregamento.
      api.post = async () => { throw { response: { data: { error: 'Falha', errors: ['Falha'] } } } }
      await page.state.handleResendOtp()
      assert.equal(page.state.resendingOtp.value, false)
    } finally { page.unmount() }
  }
})
