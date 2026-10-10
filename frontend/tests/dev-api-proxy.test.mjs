import test from 'node:test'
import assert from 'node:assert/strict'
import http from 'node:http'
import { fileURLToPath } from 'node:url'
import { createServer, loadConfigFromFile } from 'vite'

function request(port, path, { method = 'POST', headers = {} } = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request({ hostname: '127.0.0.1', port, path, method,
      headers: { Host: `172.16.0.2:${port}`, ...headers } }, response => {
      const chunks = []
      response.on('data', chunk => chunks.push(chunk))
      response.on('end', () => resolve({ status: response.statusCode, headers: response.headers,
        body: Buffer.concat(chunks).toString() }))
    })
    req.on('error', reject)
    req.end()
  })
}

test('Vite LAN proxy preserves auth paths headers and HttpOnly cookies on login and F5', async () => {
  const { config } = await loadConfigFromFile({ command: 'serve', mode: 'development' },
    fileURLToPath(new URL('../vite.config.ts', import.meta.url)))
  const proxy = config.server.proxy['/api']
  assert.equal(proxy.target, 'http://127.0.0.1:3000')
  const observed = []
  const backend = http.createServer((req, res) => {
    observed.push({ path: req.url, headers: req.headers })
    res.setHeader('Content-Type', 'application/json')
    if (req.url === '/api/devise_users/sign_in') {
      res.setHeader('Set-Cookie', 'staff_session_recovery=encrypted-test-cookie; Path=/api/devise_users; HttpOnly; SameSite=Strict')
      res.end(JSON.stringify({ staff_csrf_token: 'csrf' }))
    } else if (req.url === '/api/devise_users/restore_session' &&
        req.headers.cookie === 'staff_session_recovery=encrypted-test-cookie' &&
        req.headers['x-csrf-token'] === 'csrf') {
      res.setHeader('access-token', 'restored')
      res.end(JSON.stringify({ data: { role: 'owner' } }))
    } else {
      res.statusCode = 401
      res.end('{}')
    }
  })
  let vite
  try {
    await new Promise(resolve => backend.listen(0, '127.0.0.1', resolve))
    vite = await createServer({ ...config, configFile: false, envFile: false,
      plugins: [], optimizeDeps: { noDiscovery: true, include: [] }, logLevel: 'silent',
      server: { ...config.server, host: '127.0.0.1', port: 0, hmr: false,
        proxy: { '/api': { ...proxy, target: `http://127.0.0.1:${backend.address().port}` } } } })
    await vite.listen()
    const port = vite.httpServer.address().port
    const login = await request(port, '/api/devise_users/sign_in')
    assert.equal(login.status, 200)
    const setCookie = login.headers['set-cookie'][0]
    assert.match(setCookie, /HttpOnly/)
    assert.match(setCookie, /SameSite=Strict/)
    assert.match(setCookie, /Path=\/api\/devise_users/)
    assert.doesNotMatch(setCookie, /Domain=/i)
    const recovered = await request(port, '/api/devise_users/restore_session', {
      headers: { Cookie: setCookie.split(';')[0], 'X-CSRF-Token': 'csrf',
        'X-Staff-Client': 'client', 'X-Staff-Uid': 'owner@example.test' }
    })
    assert.equal(recovered.status, 200)
    assert.equal(recovered.headers['access-token'], 'restored')
    assert.equal(observed[1].headers['x-staff-client'], 'client')
    assert.equal(observed[1].headers['x-staff-uid'], 'owner@example.test')
    assert.equal(observed[1].headers['x-forwarded-for'], '127.0.0.1')
    assert.deepEqual(observed.map(value => value.path),
      ['/api/devise_users/sign_in', '/api/devise_users/restore_session'])
    const anonymous = await request(port, '/api/devise_users/restore_session')
    assert.equal(anonymous.status, 401)
  } finally {
    if (vite) await vite.close()
    await new Promise(resolve => backend.close(resolve))
  }
})
