class CreateBusinessHours < ActiveRecord::Migration[8.1]
  def change
    create_table :business_hours do |t|
      t.time :end_time
      t.bigint :establishment_id, null: false
      t.boolean :is_open, default: true
      t.time :start_time
      t.integer :weekday, null: false

      t.timestamps
    end

    add_index :business_hours, [:establishment_id, :weekday], unique: true, name: "index_business_hours_on_establishment_and_weekday"
    add_index :business_hours, :establishment_id
    add_foreign_key :business_hours, :establishments
  end
end