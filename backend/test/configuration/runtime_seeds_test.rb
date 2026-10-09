require 'test_helper'

class RuntimeSeedsTest < ActiveSupport::TestCase
  setup do
    @previous_email = ENV['BOOTSTRAP_ADMIN_EMAIL']
    @previous_password = ENV['BOOTSTRAP_ADMIN_PASSWORD']
    ENV['BOOTSTRAP_ADMIN_EMAIL'] = "bootstrap-#{SecureRandom.hex(6)}@example.test"
    ENV['BOOTSTRAP_ADMIN_PASSWORD'] = "Aa9!#{SecureRandom.hex(20)}"
  end

  teardown do
    ENV['BOOTSTRAP_ADMIN_EMAIL'] = @previous_email
    ENV['BOOTSTRAP_ADMIN_PASSWORD'] = @previous_password
  end

  test 'bootstrap preserves existing accounts and is idempotent' do
    existing = User.create!(name: 'Existing User', role: 'owner',
                            email: "existing-#{SecureRandom.hex(6)}@example.test",
                            password: "Aa9!#{SecureRandom.hex(20)}")
    load Rails.root.join('db/seeds/runtime.rb')
    assert User.exists?(existing.id)
    admin = User.find_by!(email: ENV.fetch('BOOTSTRAP_ADMIN_EMAIL'))
    assert admin.super_admin?
    digest = admin.encrypted_password
    user_count = User.count
    plan_count = Plan.count
    load Rails.root.join('db/seeds/runtime.rb')
    assert_equal user_count, User.count
    assert_equal plan_count, Plan.count
    assert_equal digest, admin.reload.encrypted_password
  end

  test 'bootstrap cannot promote an existing ordinary account' do
    existing = User.create!(name: 'Existing User', role: 'owner',
                            email: ENV.fetch('BOOTSTRAP_ADMIN_EMAIL'),
                            password: "Aa9!#{SecureRandom.hex(20)}")
    assert_raises(RuntimeError) { load Rails.root.join('db/seeds/runtime.rb') }
    assert_equal 'owner', existing.reload.role
  end

  test 'bootstrap rejects incomplete admin credentials without creating accounts' do
    ENV.delete('BOOTSTRAP_ADMIN_PASSWORD')
    count = User.count
    assert_raises(RuntimeError) { load Rails.root.join('db/seeds/runtime.rb') }
    assert_equal count, User.count
  end
end
