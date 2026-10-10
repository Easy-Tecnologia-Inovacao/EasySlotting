class HardenLoginSessions < ActiveRecord::Migration[8.1]
  def up
    %i[users customers].each do |table|
      add_column table, :first_login_at, :datetime
      add_column table, :login_otp_attempts, :integer, default: 0, null: false
      # Contas que já tinham dispositivos registrados não ganham um novo primeiro acesso.
      execute "UPDATE #{table} SET first_login_at = updated_at WHERE trusted_ips <> '[]'::jsonb"
      execute "UPDATE #{table} SET login_otp_code = NULL, login_otp_sent_at = NULL"
    end
    add_column :customers, :auth_session_id, :string
  end

  def down
    remove_column :customers, :auth_session_id
    %i[users customers].each do |table|
      remove_column table, :login_otp_attempts
      remove_column table, :first_login_at
    end
  end
end
