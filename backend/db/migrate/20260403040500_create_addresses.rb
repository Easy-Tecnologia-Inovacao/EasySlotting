class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :city
      t.string :complement
      t.string :country, default: "Brasil"
      t.bigint :establishment_id, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :neighborhood
      t.string :number
      t.string :state
      t.string :street
      t.string :zip_code

      t.timestamps
    end

    add_index :addresses, :establishment_id, unique: true
    add_foreign_key :addresses, :establishments
  end
end