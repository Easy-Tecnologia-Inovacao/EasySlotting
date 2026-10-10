class Account::UsersController < ApplicationController
  before_action :authenticate_user!
  # O UID do header ainda não autenticado não pode consumir a quota de terceiros.
  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }, name: 'account',
    with: -> {
      response.headers['Retry-After'] = '60'
      render json: { error: 'Muitas solicitações. Aguarde um minuto e tente novamente.' }, status: :too_many_requests
    }

  # GET /api/me/export
  # LGPD Art. 18-V — Direito à portabilidade de dados
  def export
    user = current_user

    # Dados do estabelecimento (se owner)
    establishment_data = nil
    if user.owner?
      est = user.owned_establishments.first
      if est
        establishment_data = {
          nome: est.name,
          slug: est.slug,
          cnpj: est.cnpj_masked,
          telefone: est.phone,
          whatsapp: est.whatsapp,
          criado_em: est.created_at&.iso8601
        }
      end
    end

    # Agendamentos (se employee)
    appointments = user.employee_appointments
                       .includes(:service, :customer)
                       .order(created_at: :desc)
                       .limit(500)
                       .map do |apt|
      {
        data: apt.appointment_date&.to_s,
        hora: apt.start_time&.to_s,
        servico: apt.service&.name,
        cliente: apt.customer_name_snapshot || apt.customer&.name,
        status: apt.status,
        criado_em: apt.created_at&.iso8601
      }
    end

    # Membroships
    memberships = user.establishment_memberships
                      .includes(:establishment)
                      .map do |m|
      {
        estabelecimento: m.establishment&.name,
        cargo: m.role,
        desde: m.created_at&.iso8601
      }
    end

    export_data = {
      dados_pessoais: {
        nome: user.name,
        email: user.email,
        telefone: user.phone,
        celular: user.cellphone,
        cargo: user.role,
        data_criacao: user.created_at&.iso8601,
        consentimento_termos: user.consent_terms_at&.iso8601,
        consentimento_privacidade: user.consent_privacy_at&.iso8601
      },
      estabelecimento: establishment_data,
      memberships: memberships,
      agendamentos_recentes: appointments,
      exportado_em: Time.current.iso8601,
      versao: '1.0'
    }

    AuditLogger.log(
      action: 'data_exported',
      user: user,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: { event: 'lgpd_data_export' }
    )

    send_data export_data.to_json,
              filename: "dados_usuario_#{user.id}_#{Time.current.strftime('%Y%m%d')}.json",
              type: 'application/json'
  rescue => e
    Rails.logger.error("[Account::UsersController#export] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao exportar dados.' }, status: :unprocessable_entity
  end

  # DELETE /api/me/account
  # Exclusão de conta do owner/employee (LGPD Art. 18-VI)
  def destroy
    if params[:confirmation] != current_user.email
      return render json: {
        error: 'Confirmação inválida. Digite seu e-mail para confirmar.'
      }, status: :unprocessable_entity
    end

    user_name = current_user.name
    user_email = current_user.email
    user_role = current_user.role

    # Apenas employees podem se auto-excluir. Owners precisam ser removidos pelo super_admin.
    if current_user.owner?
      return render json: {
        error: 'Proprietários não podem excluir a própria conta pelo sistema. Entre em contato com o suporte.'
      }, status: :forbidden
    end

    AuditLogger.log(
      action: 'account_deleted',
      user: current_user,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'account_deleted',
        user_name: user_name,
        user_email: user_email,
        role: user_role
      }
    )

    # Remove memberships e dados vinculados
    current_user.establishment_memberships.destroy_all
    current_user.employee_services.destroy_all
    current_user.archived_employee_records.update_all(user_id: nil)

    # Soft delete com anonimização de PII
    current_user.update!(
      name: 'Conta Excluída',
      email: "deleted_#{current_user.id}_#{Time.current.to_i}@deleted.local",
      phone: nil,
      cellphone: nil,
      image: nil,
      encrypted_password: '',
      tokens: {},
      active: false,
      role: 'employee',
      password_changed_at: nil
    )

    # Invalida sessão atual
    current_user.update!(tokens: {}) rescue nil

    render json: { message: 'Conta excluída com sucesso.' }, status: :ok
  rescue => e
    Rails.logger.error("[Account::UsersController#destroy] #{e.class}: #{e.message}")
    render json: { error: 'Não foi possível excluir a conta. Tente novamente.' }, status: :unprocessable_entity
  end

  # PATCH /api/me/revoke_consent
  # LGPD Art. 8º, §5º — Direito de revogar consentimento
  def revoke_consent
    if current_user.owner?
      return render json: {
        error: 'Proprietários não podem revogar consentimento pelo sistema. Entre em contato com o suporte.'
      }, status: :forbidden
    end

    AuditLogger.log(
      action: 'consent_revoked',
      user: current_user,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: { event: 'consent_revoked', user_email: current_user.email }
    )

    current_user.update!(
      consent_terms_at: nil,
      consent_privacy_at: nil,
      active: false,
      tokens: {}
    )

    current_user.establishment_memberships.destroy_all

    render json: { message: 'Consentimento revogado. Sua conta foi desativada.' }, status: :ok
  end

  def change_password
    if params[:password].blank? || params[:password_confirmation].blank?
      render json: { error: 'Preencha senha e confirmação.' }, status: :unprocessable_entity
      return
    end

    if params[:current_password].blank?
      render json: { error: 'Informe a senha atual para alterar.' }, status: :unprocessable_entity
      return
    end

    valid_current = if current_user.respond_to?(:authenticate)
                      current_user.authenticate(params[:current_password])
                    else
                      current_user.valid_password?(params[:current_password])
                    end

    unless valid_current
      AuditLogger.log(
        action: 'password_change_failed',
        user: current_user,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: { event: 'password_change_failed', reason: 'invalid_current_password' }
      )
      render json: { error: 'A senha atual está incorreta.' }, status: :unprocessable_entity
      return
    end

    if params[:password] == params[:current_password]
      render json: { error: 'A nova senha deve ser diferente da atual.' }, status: :unprocessable_entity
      return
    end

    password_expired = current_user.password_changed_at.nil? || current_user.password_changed_at < 90.days.ago

    if params[:password] != params[:password_confirmation]
      render json: { error: 'A confirmação da senha não confere.' }, status: :unprocessable_entity
      return
    end

    current_user.password = params[:password]
    current_user.password_confirmation = params[:password_confirmation]
    current_user.allow_password_change = true

    if current_user.save
      AuditLogger.log(
        action: 'password_changed',
        user: current_user,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: { event: 'password_changed', forced: password_expired }
      )

      SecurityAlertMailer.password_changed(
        user: current_user,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        change_time: Time.current
      ).deliver_later

      render json: {
        message: 'Senha alterada com sucesso.',
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          role: current_user.role,
          allow_password_change: current_user.allow_password_change
        }
      }, status: :ok
    else
      render json: {
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/me/sessions
  def sessions
    current_client = request.headers['client']
    policy = OwnerSessionPolicy.new(current_user)
    tokens = policy.permitted_tokens

    session_list = tokens.map do |client_id, data|
      {
        client_id: client_id,
        is_current: client_id == current_client,
        device: data['name'] || 'Dispositivo Desconhecido',
        ip: data['ip'],
        last_seen_at: data['last_seen_at'] ? Time.at(data['last_seen_at']).iso8601 : nil,
        expires_at: Time.at(data['expiry'].to_i).iso8601
      }
    end.sort_by { |s| s[:is_current] ? 0 : 1 }

    render json: { sessions: session_list, limit: policy.limit, active_count: session_list.size }, status: :ok
  end

  # DELETE /api/me/sessions/:client_id
  def destroy_session
    client_id_to_remove = params[:client_id]
    unless client_id_to_remove.is_a?(String) && client_id_to_remove.match?(/\A[a-zA-Z0-9_-]{1,128}\z/)
      return render json: { error: 'Sessão não encontrada.' }, status: :not_found
    end
    removed = current_user.with_lock do
      tokens = (current_user.tokens || {}).dup
      if tokens.key?(client_id_to_remove)
        tokens.delete(client_id_to_remove)
        current_user.update_columns(tokens: tokens)
        true
      end
    end

    if removed

      AuditLogger.log(
        action: 'session_revoked',
        user: current_user,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: { revoked_client_digest: Digest::SHA256.hexdigest("staff-session:#{client_id_to_remove}") }
      )

      render json: { message: 'Sessão encerrada com sucesso.' }, status: :ok
    else
      render json: { error: 'Sessão não encontrada.' }, status: :not_found
    end
  end

  # DELETE /api/me/sessions
  def destroy_other_sessions
    current_client = request.headers['client']
    current_user.with_lock do
      tokens = (current_user.tokens || {}).dup
      tokens = current_client.present? && tokens.key?(current_client) ? { current_client => tokens[current_client] } : {}
      current_user.update_columns(tokens: tokens)
    end

    AuditLogger.log(
      action: 'other_sessions_revoked',
      user: current_user,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )

    render json: { message: 'Todas as outras sessões foram encerradas.' }, status: :ok
  end
end
