class AddCellphoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cellphone, :string
  end
end
