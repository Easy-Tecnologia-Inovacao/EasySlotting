# app/controllers/customer/profile_controller.rb
# Perfil do customer logado via JWT.
# Segurança: autenticação JWT obrigatória, validação de entrada,
# auditoria de alterações, proteção contra abuse.

require 'vips'

class Customer::ProfileController < ApplicationController
  before_action :authenticate_customer!

  RATE_LIMIT_WINDOW = 1.hour
  MAX_UPDATES_PER_WINDOW = 10

  # GET /api/customer/profile
  def show
    render json: { customer: current_customer.as_safe_json }
  end

  # GET /api/customer/profile/export
  # LGPD Art. 18(V) — Direito à portabilidade de dados
  def export
    appointments = current_customer.appointments
                                  .includes(:service, :employee)
                                  .order(created_at: :desc)
                                  .map do |apt|
      {
        data: apt.appointment_date&.to_s,
        hora: apt.start_time&.to_s,
        servico: apt.service&.name,
        profissional: apt.employee&.name,
        status: apt.status,
        valor: apt.total_amount,
        criado_em: apt.created_at&.iso8601
      }
    end

    packages = current_customer.service_package_sales
                               .includes(:service_package)
                               .order(created_at: :desc)
                               .map do |ps|
      {
        plano: ps.service_package&.name,
        sessoes_total: ps.total_sessions,
        sessoes_utilizadas: ps.used_sessions,
        data_compra: ps.created_at&.iso8601
      }
    end

    export_data = {
      dados_pessoais: {
        nome: current_customer.name,
        email: current_customer.email,
        telefone: current_customer.phone,
        celular: current_customer.cellphone,
        data_criacao: current_customer.created_at&.iso8601,
        consentimento_termos: current_customer.consent_terms_at&.iso8601,
        consentimento_privacidade: current_customer.consent_privacy_at&.iso8601
      },
      agendamentos: appointments,
      pacotes: packages,
      exportado_em: Time.current.iso8601,
      versao: '1.0'
    }

    AuditLogger.log(
      action: 'data_exported',
      user: current_customer,
      establishment: current_customer.establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: { event: 'lgpd_data_export' }
    )

    send_data export_data.to_json,
              filename: "dados_#{current_customer.id}_#{Time.current.strftime('%Y%m%d')}.json",
              type: 'application/json'
  end

  # PUT /PATCH /api/customer/profile
  def update
    # Rate limiting: máximo de atualizações por hora
    recent_updates = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: 'profile_updated',
      created_at: RATE_LIMIT_WINDOW.ago..
    ).where(
      '(auditable_type = ? AND auditable_id = ?) OR user_id = ?',
      'Customer', current_customer.id, current_customer.id
    ).count

    if recent_updates >= MAX_UPDATES_PER_WINDOW
      return render json: {
        error: 'Muitas atualizações. Aguarde antes de alterar novamente.'
      }, status: :too_many_requests
    end

    old_data = {
      name: current_customer.name,
      email: current_customer.email,
      phone: current_customer.phone,
      cellphone: current_customer.cellphone
    }

    if current_customer.update(profile_params)
      # Auditoria da alteração
      changes = current_customer.saved_changes.except(
        'updated_at', 'created_at', 'password_digest',
        'refresh_token', 'refresh_token_expires_at'
      ).select { |k, _| old_data.key?(k.to_sym) }

      if changes.present?
        AuditLogger.log(
          action: 'profile_updated',
          user: current_customer,
          establishment: current_customer.establishment,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          details: {
            event: 'profile_updated',
            changes: changes.transform_values { |v| v.is_a?(Array) ? v.last : v }
          }
        )
      end

      render json: {
        message:  'Perfil atualizado com sucesso',
        customer: current_customer.as_safe_json
      }, status: :ok
    else
      render json: { errors: current_customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/customer/profile/change_password
  def change_password
    # Rate limiting: máximo de tentativas falhas de troca de senha (15 minutos)
    failed_recent = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: 'password_change_failed',
      created_at: 15.minutes.ago..
    ).where(
      '(auditable_type = ? AND auditable_id = ?) OR user_id = ?',
      'Customer', current_customer.id, current_customer.id
    ).count

    if failed_recent >= 5
      return render json: {
        error: 'Muitas tentativas incorretas. Aguarde 15 minutos antes de tentar novamente.'
      }, status: :too_many_requests
    end

    if params[:password].blank? || params[:password_confirmation].blank?
      return render json: { error: 'Preencha todos os campos de senha.' }, status: :unprocessable_entity
    end

    if params[:current_password].blank?
      return render json: { error: 'Informe a senha atual para alterar.' }, status: :unprocessable_entity
    end

    unless current_customer.authenticate(params[:current_password])
      AuditLogger.log(
        action: 'password_change_failed',
        user: current_customer,
        establishment: current_customer.establishment,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: { event: 'password_change_failed', reason: 'invalid_current_password' }
      )
      return render json: { error: 'Senha atual incorreta.' }, status: :unprocessable_entity
    end

    if params[:password] == params[:current_password]
      return render json: { error: 'A nova senha deve ser diferente da atual.' }, status: :unprocessable_entity
    end

    password_expired = current_customer.password_changed_at.nil? || current_customer.password_changed_at < 90.days.ago

    if params[:password] != params[:password_confirmation]
      return render json: { error: 'As senhas não coincidem.' }, status: :unprocessable_entity
    end

    current_customer.password = params[:password]
    current_customer.password_confirmation = params[:password_confirmation]

    if current_customer.save
      current_customer.update!(refresh_token: nil, refresh_token_expires_at: nil)

      AuditLogger.log(
        action: 'password_changed',
        user: current_customer,
        establishment: current_customer.establishment,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: { event: 'password_changed', forced: password_expired }
      )

      SecurityAlertMailer.password_changed(
        user: current_customer,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        change_time: Time.current
      ).deliver_later

      render json: { message: 'Senha alterada com sucesso. Faça login novamente.' }, status: :ok
    else
      render json: { errors: current_customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/customer/profile
  def destroy
    # Validação de segurança: confirmação obrigatória
    if params[:confirmation] != current_customer.email
      return render json: {
        error: 'Confirmação inválida. Digite seu e-mail para confirmar.'
      }, status: :unprocessable_entity
    end

    customer_name = current_customer.name
    customer_email = current_customer.email

    # Auditoria antes da exclusão
    AuditLogger.log(
      action: 'account_deleted',
      user: current_customer,
      establishment: current_customer.establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'account_deleted',
        customer_name: customer_name,
        customer_email: customer_email
      }
    )

    # Cancela agendamentos pendentes
    current_customer.appointments
      .where(status: %w[pending confirmed])
      .update_all(status: 'canceled')

    # Cancela pacotes ativos
    current_customer.service_package_sales
      .where(status: 'active')
      .update_all(status: 'canceled')

    # Remove dados sensíveis e soft delete
    current_customer.update!(
      name: 'Conta Excluída',
      email: "deleted_#{current_customer.id}_#{Time.current.to_i}@deleted.local",
      phone: nil,
      cellphone: nil,
      image: nil,
      password_digest: nil,
      active: false,
      refresh_token: nil,
      refresh_token_expires_at: nil
    )

    render json: { message: 'Conta excluída com sucesso.' }, status: :ok
  rescue => e
    Rails.logger.error("[Customer::ProfileController#destroy] #{e.class}: #{e.message}")
    render json: { error: 'Não foi possível excluir a conta. Tente novamente.' }, status: :unprocessable_entity
  end

  # PATCH /api/customer/profile/revoke_consent
  # LGPD Art. 8º, §5º — Direito de revogar consentimento
  def revoke_consent
    AuditLogger.log(
      action: 'consent_revoked',
      user: current_customer,
      establishment: current_customer.establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: { event: 'consent_revoked', customer_email: current_customer.email }
    )

    # Revogar consentimento = desativar conta (LGPD)
    current_customer.update!(
      consent_terms_at: nil,
      consent_privacy_at: nil,
      active: false,
      refresh_token: nil,
      refresh_token_expires_at: nil
    )

    # Cancela agendamentos pendentes
    current_customer.appointments
      .where(status: %w[pending confirmed])
      .update_all(status: 'canceled')

    render json: { message: 'Consentimento revogado. Sua conta foi desativada.' }, status: :ok
  end

  # POST /api/customer/profile/upload_image
  def upload_image
    if params[:image].blank?
      return render json: { error: 'Nenhuma imagem enviada.' }, status: :unprocessable_entity
    end

    old_path = current_customer.image

    begin
      path = save_uploaded_image(params[:image], current_customer.id)

      if current_customer.update(image: path)
        delete_file_if_exists(old_path) if old_path.present? && old_path != path

        AuditLogger.log(
          action: 'profile_image_changed',
          user: current_customer,
          establishment: current_customer.establishment,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          details: { event: 'profile_image_changed' }
        )

        render json: { message: 'Foto atualizada com sucesso', image: path }, status: :ok
      else
        render json: { errors: current_customer.errors.full_messages }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error("[Customer::ProfileController#upload_image] #{e.class}: #{e.message}")
      render json: { error: 'Erro ao fazer upload da imagem.' }, status: :unprocessable_entity
    end
  end

  # GET /api/customer/profile/sessions
  def sessions
    # Retorna informações sobre sessões ativas (últimos logins)
    recent_logs = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: %w[login_success login_failure],
      auditable_type: 'Customer',
      auditable_id: current_customer.id
    ).order(created_at: :desc).limit(10).map do |log|
      {
        action: log.action,
        ip: log.ip_address,
        device: log.details&.dig('device'),
        location: log.details&.dig('location'),
        created_at: log.created_at
      }
    end

    render json: { sessions: recent_logs }, status: :ok
  end

  private

  def profile_params
    # Senha NÃO é alterada via update — usar change_password para isso
    params.require(:customer).permit(:name, :email, :phone, :cellphone)
  end

  def save_uploaded_image(file, customer_id)
    # 1. Limite de tamanho (5MB)
    if file.size > 5.megabytes
      raise StandardError, 'Arquivo muito grande. Limite de 5MB.'
    end

    # 2. Verificação de tipo real (Whitelist: JPEG, PNG, WEBP - SVG bloqueado por segurança)
    allowed_types = %w[image/jpeg image/png image/webp]
    detected_type = Marcel::MimeType.for(file.tempfile)

    unless allowed_types.include?(detected_type)
      raise StandardError, 'Formato inválido. Envie apenas .jpg, .png ou .webp.'
    end

    # 🔒 SEGURANÇA: A extensão DEVE ser derivada estritamente do MIME type detectado,
    # NUNCA do nome original enviado pelo cliente (file.original_filename)
    extension = case detected_type
                when 'image/jpeg' then '.jpg'
                when 'image/png'  then '.png'
                when 'image/webp' then '.webp'
                else '.jpg'
                end

    filename   = "avatar_customer_#{customer_id.to_i}_#{Time.current.to_i}_#{SecureRandom.hex(4)}#{extension}"
    upload_dir = Rails.root.join('public', 'uploads', 'customers')
    FileUtils.mkdir_p(upload_dir)

    file_path = upload_dir.join(filename)

    # Reencoda o conteúdo para garantir que o arquivo público seja uma imagem
    # válida, além de impedir dimensões que possam causar consumo excessivo.
    data = file.read
    image = Vips::Image.new_from_buffer(data, '', access: :sequential)
    pixel_count = image.width.to_i * image.height.to_i
    raise StandardError, 'Dimensões da imagem excedem o limite permitido.' if image.width > 5000 || image.height > 5000 || pixel_count > 25_000_000

    options = detected_type == 'image/png' ? { compression: 6, strip: true } : { Q: 85, strip: true }
    image.write_to_file(file_path.to_s, **options)

    "/uploads/customers/#{filename}"
  end

  def delete_file_if_exists(relative_path)
    return if relative_path.blank?
    return if relative_path.start_with?('http://', 'https://')

    full_path = File.expand_path(relative_path.sub(%r{\A/}, ''), Rails.root.join('public'))
    allowed_dir = Rails.root.join('public', 'uploads', 'customers').to_s

    # Defesa em profundidade: impede exclusão fora da pasta designada de avatares (prevenção contra Path Traversal)
    return unless full_path.start_with?(allowed_dir)

    File.delete(full_path) if File.exist?(full_path)
  end
end
