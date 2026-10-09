class AddLoginOtpAndTrustedIps < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :login_otp_code, :string
    add_column :users, :login_otp_sent_at, :datetime
    add_column :users, :trusted_ips, :jsonb, default: []

    add_column :customers, :login_otp_code, :string
    add_column :customers, :login_otp_sent_at, :datetime
    add_column :customers, :trusted_ips, :jsonb, default: []
  end
end
