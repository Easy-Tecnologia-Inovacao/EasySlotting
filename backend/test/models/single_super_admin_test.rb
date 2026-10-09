require 'test_helper'

class SingleSuperAdminTest < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  test 'only one super admin exists even with concurrent inserts and validations bypassed' do
    emails = 2.times.map { "single-#{SecureRandom.hex(6)}@example.test" }
    ready, start, results = Queue.new, Queue.new, Queue.new
    threads = emails.map do |email|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          user = User.new(name: 'Administrador', email: email, password: 'TesteSeguro#2026', role: 'super_admin')
          ready << true
          start.pop
          begin
            user.save!(validate: false)
            results << :created
          rescue ActiveRecord::RecordNotUnique
            results << :conflict
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)
    assert_equal [:conflict, :created], 2.times.map { results.pop }.sort
    admin = User.find_by!(email: emails, role: 'super_admin')
    admin.update!(active: false)
    other = User.new(name: 'Segundo Administrador', email: "second-#{SecureRandom.hex(6)}@example.test", password: 'TesteSeguro#2026', role: 'super_admin')
    assert_not other.valid?
    assert other.errors[:role].present?
  ensure
    User.where(email: emails).delete_all if emails
  end
end
