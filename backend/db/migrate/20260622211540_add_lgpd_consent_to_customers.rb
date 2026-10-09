class AddLgpdConsentToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :consent_terms_at, :datetime
    add_index :customers, :consent_terms_at, unique: true
    add_column :customers, :consent_privacy_at, :datetime
    add_index :customers, :consent_privacy_at, unique: true
  end
end
