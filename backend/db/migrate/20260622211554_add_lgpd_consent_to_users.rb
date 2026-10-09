class AddLgpdConsentToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :consent_terms_at, :datetime
    add_column :users, :consent_privacy_at, :datetime
  end
end
