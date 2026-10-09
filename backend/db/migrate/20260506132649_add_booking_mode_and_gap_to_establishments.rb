class AddBookingModeAndGapToEstablishments < ActiveRecord::Migration[8.1]
  def change
    add_column :establishments, :booking_mode, :string, default: 'time'
    add_column :establishments, :gap_minutes, :integer, default: 0
  end
end
