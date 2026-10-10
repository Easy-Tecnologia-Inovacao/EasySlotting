require 'test_helper'

class SecurityLogsTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @admin = User.create!(name: 'Review', email: "logs-#{SecureRandom.hex(6)}@example.test", password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = @admin.create_new_auth_token
    Rails.cache.delete('super_admin/security_summary/v2')
  end
  teardown { Rack::Attack.enabled = @attack }
  def query(params = {}, endpoint = '')
    get "/api/super_admin/audit_logs#{endpoint}", headers: @headers, params: params, as: :json
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end

  test 'all endpoints enforce server authorization' do
    ['', '/security_summary', '/filter_options'].each do |endpoint|
      get "/api/super_admin/audit_logs#{endpoint}", as: :json
      assert_response :unauthorized
      %w[owner employee].each do |role|
        user = User.create!(name: 'Review', email: "logs-#{SecureRandom.hex(6)}@example.test", password: 'TesteSeguro#2026', role: role)
        get "/api/super_admin/audit_logs#{endpoint}", headers: user.create_new_auth_token, params: { role: 'super_admin' }, as: :json
        assert_response :forbidden
      end
      query({}, endpoint)
      assert_response :ok
      assert_equal 'no-store', response.headers['Cache-Control']
    end
  end

  test 'explicit response excludes arbitrary details and handles historical malformed details' do
    record = AuditLog.create!(action: 'login', details: { password: 'synthetic', nested: { password: 'synthetic' }, otp_code: 'synthetic', device: 'x' * 1000, location: { city: 'Cidade', token: 'synthetic', region: ['bad'] } })
    AuditLog.create!(action: 'logout', details: ['malformed'])
    query
    assert_response :ok
    row = response.parsed_body['logs'].find { |item| item['id'] == record.id }
    assert_equal %w[action device establishment id ip_address location timestamp user], row.keys.sort
    assert_not_includes response.body, 'synthetic'
    assert_equal 120, row['device'].length
    assert_equal({ 'city' => 'Cidade', 'region' => nil, 'country' => nil }, row['location'])
  end

  test 'invalid scalar formats ranges and dates return validation errors' do
    [{ page: ['1'] }, { page: {} }, { page: 501 }, { page: 0 }, { page: '1.5' },
     { per_page: 201 }, { per_page: [] }, { user_id: '-1' }, { establishment_id: '9' * 30 },
     { action_type: 'unknown' }, { action_type: [] }, { start_date: '2026-02-30' },
     { start_date: 'yesterday' }, { end_date: {} }, { start_date: '2026-10-11', end_date: '2026-10-10' }].each do |params|
      query(params)
      assert_response :unprocessable_entity
      assert_not response.parsed_body.key?('logs')
    end
  end

  test 'password aliases include history and session filter excludes unrelated events' do
    ids = %w[password_changed password_change].map { |action| AuditLog.create!(action: action).id }
    revoked = AuditLog.create!(action: 'session_revoked')
    %w[password_changed password_change].each do |action|
      query(action_type: action)
      assert_equal ids.sort, response.parsed_body['logs'].map { |row| row['id'] }.sort
    end
    query(action_type: 'session_revoked')
    assert_equal [revoked.id], response.parsed_body['logs'].map { |row| row['id'] }
  end

  test 'date boundaries and stable pagination' do
    stamp = Time.zone.local(2026, 10, 10, 12)
    first = AuditLog.create!(action: 'login', created_at: stamp)
    second = AuditLog.create!(action: 'login', created_at: stamp)
    AuditLog.create!(action: 'login', created_at: stamp.next_day.beginning_of_day)
    query(start_date: '2026-10-10', end_date: '2026-10-10', per_page: 1)
    assert_equal [second.id], response.parsed_body['logs'].map { |row| row['id'] }
    query(start_date: '2026-10-10', end_date: '2026-10-10', per_page: 1, page: 2)
    assert_equal [first.id], response.parsed_body['logs'].map { |row| row['id'] }
  end

  test 'summary contains only bounded indicators within last day' do
    baseline = AuditLog.where(action: 'login', created_at: 24.hours.ago..Time.current).count
    AuditLog.create!(action: 'login_failed', ip_address: '203.0.113.1')
    AuditLog.create!(action: 'login_failed', ip_address: '203.0.113.1')
    AuditLog.create!(action: 'login_failed', ip_address: nil)
    AuditLog.create!(action: 'login_failed', ip_address: '203.0.113.2', created_at: 2.days.ago)
    query({}, '/security_summary')
    assert_equal %w[generated_at summary], response.parsed_body.keys.sort
    assert_equal({ 'logins_24h' => baseline, 'failed_logins_24h' => 3, 'suspicious_ip_count' => 1 }, response.parsed_body['summary'])
    assert_not_includes response.body, '203.0.113'
  end

  test 'options are minimal limited and search escapes wildcards' do
    owner = User.create!(name: 'Owner', email: "owner-#{SecureRandom.hex(6)}@example.test", password: 'TesteSeguro#2026', role: 'owner')
    51.times { |i| Establishment.create!(name: "Empresa #{i}", slug: "review-#{SecureRandom.hex(6)}", owner: owner) }
    query({}, '/filter_options')
    body = response.parsed_body
    assert_equal 50, body['establishments'].length
    assert body['has_more']
    assert_equal %w[id name], body['establishments'].first.keys.sort
    assert_includes body['actions'].map { |row| row['value'] }, 'session_revoked'
    query({ q: '%' }, '/filter_options')
    assert_empty response.parsed_body['establishments']
    query({ q: [] }, '/filter_options')
    assert_response :unprocessable_entity
  end
end
