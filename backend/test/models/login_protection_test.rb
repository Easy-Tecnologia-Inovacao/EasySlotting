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

  test 'first access and unknown IP require OTP while a confirmed IP is enough' do
    assert @user.login_otp_required?(ip: @context[:ip])
    @user.add_trusted_ip!(ip: @context[:ip])
    assert @user.trusted_ip?(ip: @context[:ip])
    assert_not @user.login_otp_required?(ip: @context[:ip])
    assert @user.login_otp_required?(ip: '192.168.1.2')
    assert @user.login_otp_required?(ip: nil)
    assert_equal [@context[:ip]], @user.reload.trusted_ips
  end

  test 'legacy device hashes are ignored and removed while IPv6 addresses are normalized' do
    @user.update_columns(trusted_ips: ['device:' + 'a' * 64, 'not-an-ip', '2001:0db8:0:0:0:0:0:1'])
    assert @user.trusted_ip?(ip: '2001:db8::1')
    assert @user.login_otp_required?(ip: '2001:db8::1'), 'an IP entry must not bypass first-login verification'
    assert_not @user.trusted_ip?(ip: '192.168.1.1')
    @user.add_trusted_ip!(ip: '2001:db8::1')
    assert_equal ['2001:db8::1'], @user.reload.trusted_ips
  end

  test 'invalid addresses and network ranges cannot become trusted and old IPs eventually require verification again' do
    [nil, '', '192.168.1.0/24', 'not-an-ip', ['127.0.0.1']].each do |invalid|
      @user.add_trusted_ip!(ip: invalid)
      assert @user.login_otp_required?(ip: invalid)
    end
    assert_nil @user.reload.first_login_at
    assert_empty @user.trusted_ips
    31.times { |number| @user.add_trusted_ip!(ip: "192.0.2.#{number + 1}") }
    assert_equal 30, @user.reload.trusted_ips.size
    assert @user.login_otp_required?(ip: '192.0.2.1')
    assert_not @user.login_otp_required?(ip: '192.0.2.31')
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
