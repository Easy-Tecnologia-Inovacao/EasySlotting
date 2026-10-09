class AddRefreshTokenToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :refresh_token, :string
    add_column :customers, :refresh_token_expires_at, :datetime
    add_index :customers, :refresh_token, unique: true, where: "(refresh_token IS NOT NULL)"
  end
end
