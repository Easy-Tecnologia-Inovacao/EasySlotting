class Financial::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_financial_access!

  def index
    render json: Financial::Reports::Generator.new(
      establishment: @establishment,
      params: report_params
    ).call
  end

  private

  def report_params
    safe = params.permit(:period, :date_from, :date_to, :team_type, :status, :page, :per_page)

    # IDOR fix: valida que employee_id pertence ao estabelecimento antes de usar
    if params[:employee_id].present?
      eid = params[:employee_id].to_i
      safe = safe.merge(employee_id: eid) if @establishment.establishment_memberships.exists?(user_id: eid)
    end

    # IDOR fix: valida que service_id pertence ao estabelecimento antes de usar
    if params[:service_id].present?
      sid = params[:service_id].to_i
      safe = safe.merge(service_id: sid) if Service.exists?(id: sid, establishment_id: @establishment.id)
    end

    safe
  end
end
