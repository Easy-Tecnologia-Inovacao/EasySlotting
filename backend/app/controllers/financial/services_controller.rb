module Financial
  class ServicesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_establishment
    before_action :require_financial_access!

    def index
      safe_params = params.permit(:period, :date_from, :date_to)
      result = Financial::ServiceReport.new(
        establishment: @establishment,
        params: safe_params
      ).call

      render json: result, status: :ok
    rescue StandardError => e
      Rails.logger.error("[Financial::Services#index] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      render json: { error: 'Erro ao carregar serviços financeiros.' }, status: :unprocessable_entity
    end
  end
end
