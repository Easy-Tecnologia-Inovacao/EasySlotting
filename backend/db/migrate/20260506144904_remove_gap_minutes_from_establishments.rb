class RemoveGapMinutesFromEstablishments < ActiveRecord::Migration[8.1]
  def change
    remove_column :establishments, :gap_minutes, :integer
  end
end
