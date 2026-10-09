require 'test_helper'

class LoginProtectionTest < ActiveSupport::TestCase
  parallelize(workers: 1)

  setup do
    @user = User.create!(name: 'Pessoa Segura', email: "otp-#{SecureRandom.hex(5)}@example.test",
                        password: 'TesteSeguro#2026', role: 'owner')
    @context = { ip: '192.168.1.1', device_token: 'a' * 64 }
  end

  test 'OTP is hashed bound to the device and consumed once' do
    code = @user.generate_login_otp!(**@context)
    assert_not_equal code, @user.reload.login_otp_code
    assert_not @user.verify_login_otp(code, **@context.merge(device_token: 'b' * 64))
    assert @user.verify_login_otp(code, **@context)
    assert_not @user.verify_login_otp(code, **@context)
  end

  test 'OTP expires and stops accepting codes after five failures' do
    code = @user.generate_login_otp!(**@context)
    wrong = code == '000000' ? '999999' : '000000'
    5.times { assert_not @user.verify_login_otp(wrong, **@context) }
    assert_not @user.verify_login_otp(code, **@context)
    assert_equal 5, @user.reload.login_otp_attempts
    travel 11.minutes
    code = @user.generate_login_otp!(**@context)
    travel 11.minutes
    assert_not @user.verify_login_otp(code, **@context)
  end

  test 'OTP resend cooldown does not reset attempts' do
    @user.generate_login_otp!(**@context)
    @user.verify_login_otp('invalid', **@context)
    assert_nil @user.generate_login_otp!(**@context)
    assert_equal 1, @user.reload.login_otp_attempts
  end

  test 'IP alone or absent context never identifies a trusted device' do
    @user.add_trusted_device!(**@context)
    assert @user.trusted_device?(**@context)
    assert_not @user.trusted_device?(ip: @context[:ip])
    assert_not @user.trusted_device?(device_token: @context[:device_token])
    assert_not @user.trusted_device?(**@context.merge(ip: '192.168.1.2'))
  end

  test 'password attempts lock the account and expired locks restart the counter' do
    5.times { @user.increment_failed_attempts! }
    assert @user.access_locked?
    travel 31.minutes do
      assert_not @user.access_locked?
      @user.increment_failed_attempts!
      assert_equal 1, @user.reload.failed_attempts
      assert_not @user.access_locked?
    end
  end
end
