class AutoCancelNoShowsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("[AutoCancelNoShowsJob] Iniciando limpeza de no-shows")
    Appointment.auto_cancel_no_shows!
    Rails.logger.info("[AutoCancelNoShowsJob] Limpeza concluída")
  end
end
