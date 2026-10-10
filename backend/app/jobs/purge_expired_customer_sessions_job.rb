class PurgeExpiredCustomerSessionsJob < ApplicationJob
  queue_as :default

  def perform
    CustomerSession.where('expires_at <= ?', Time.current).in_batches.delete_all
  end
end
