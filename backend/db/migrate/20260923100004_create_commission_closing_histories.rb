class CreateCommissionClosingHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :commission_closing_histories do |t|
      t.references :commission_closing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.string :action, null: false
      t.text   :description
      t.jsonb  :changes_snapshot, default: {}

      t.timestamps
    end
  end
end
