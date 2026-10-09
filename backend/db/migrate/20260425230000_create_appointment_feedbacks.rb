class CreateAppointmentFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :appointment_feedbacks do |t|
      # index: { unique: true } garante 1 feedback por agendamento
      t.references :appointment, null: false, foreign_key: true, index: { unique: true }
      t.references :customer,    null: false, foreign_key: true
      t.integer    :rating,      null: false
      t.text       :comment
      t.boolean    :anonymous,   null: false, default: true

      t.timestamps
    end
  end
end
