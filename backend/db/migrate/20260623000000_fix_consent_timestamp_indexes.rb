class FixConsentTimestampIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :customers, :consent_terms_at
    remove_index :customers, :consent_privacy_at

    add_index :customers, :consent_terms_at
    add_index :customers, :consent_privacy_at
  end
end
