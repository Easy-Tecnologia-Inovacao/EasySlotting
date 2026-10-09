require 'test_helper'
require 'tmpdir'

class PurgeCustomerAvatarJobTest < ActiveJob::TestCase
  test 'purges only the generated avatar of the requested customer and is idempotent' do
    Dir.mktmpdir('avatar-purge-', Rails.root.join('tmp')) do |root|
      directory = File.join(root, 'public', 'uploads', 'customers')
      FileUtils.mkdir_p(directory)
      owned = File.join(directory, 'avatar_customer_7_123_abcdef12.png')
      foreign = File.join(directory, 'avatar_customer_8_123_abcdef12.png')
      File.write(owned, 'owned')
      File.write(foreign, 'foreign')
      outside = File.join(root, 'keep.txt')
      File.write(outside, 'outside')

      job = PurgeCustomerAvatarJob.new
      job.define_singleton_method(:avatar_directory) { Pathname.new(directory) }
      job.perform(7, '/uploads/customers/avatar_customer_8_123_abcdef12.png')
      job.perform(7, '/uploads/customers/../../../keep.txt')
      job.perform(7, 'https://example.test/avatar.png')
      assert File.exist?(owned)
      assert File.exist?(foreign)
      assert File.exist?(outside)
      job.perform(7, '/uploads/customers/avatar_customer_7_123_abcdef12.png')
      assert_not File.exist?(owned)
      assert File.exist?(foreign)
      assert File.exist?(outside)
      job.perform(7, '/uploads/customers/avatar_customer_7_123_abcdef12.png')
    end
  end
end
