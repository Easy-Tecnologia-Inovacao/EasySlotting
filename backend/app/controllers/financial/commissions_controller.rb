module Financial
  class CommissionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_establishment
    before_action :require_financial_access!

    def index
      # IDOR fix: sanitiza employee_id — só aceita se pertencer ao estabelecimento
      safe_params = params.permit(:reference_month, :date_from, :date_to, :period)
      if params[:employee_id].present?
        eid = params[:employee_id].to_i
        safe_params = safe_params.merge(employee_id: eid) if @establishment.establishment_memberships.exists?(user_id: eid, active: true)
      end

      result = Financial::CommissionReport.new(
        establishment: @establishment,
        params: safe_params
      ).call

      render json: result, status: :ok
    end

    private

  end
end