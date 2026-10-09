class CreateArchivedEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :archived_employees do |t|
      t.references :establishment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :archived_by, null: true, foreign_key: { to_table: :users }

      t.string :reason
      t.datetime :archived_at, null: false
      t.jsonb :membership_data, null: false, default: {}
      t.jsonb :user_data, null: false, default: {}

      t.timestamps
    end
  end
end