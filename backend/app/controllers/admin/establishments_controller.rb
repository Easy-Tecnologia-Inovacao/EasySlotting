require 'vips'

class Admin::EstablishmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  before_action :require_establishment_management!, only: [:update, :upload_logo, :upload_banner]

  def show
    render json: serialized_establishment(@establishment)
  end

  def update
    input = params.require(:establishment)
    unless valid_settings_input?(input)
      return render json: { error: 'Configurações inválidas.' }, status: :unprocessable_entity
    end
    # 🔒 SEGURANÇA: Apenas o proprietário deste estabelecimento (ou super admin) pode alterar o tema visual (aparência)
    if params.dig(:establishment, :public_settings, :theme).present?
      unless establishment_owner?
        return render json: { error: 'Acesso negado: Apenas o proprietário pode alterar as configurações visuais do estabelecimento.' }, status: :forbidden
      end
    end

    # 🔒 SEGURANÇA: Apenas o proprietário deste estabelecimento (ou super admin) pode alterar as páginas legais (termos e privacidade)
    if input.key?(:legal_pages)
      unless establishment_owner?
        return render json: { error: 'Acesso negado: Apenas o proprietário pode alterar os termos legais e políticas de privacidade.' }, status: :forbidden
      end
    end

    ActiveRecord::Base.transaction do
      est_params = establishment_params

      # testimonials é JSONB — precisa ser extraído separadamente pois
      # Rails strong params não suporta arrays de hashes com chaves livres
      if params[:establishment][:testimonials].is_a?(Array)
        raw_testimonials = params[:establishment][:testimonials].map do |t|
          foto_raw = t[:foto].to_s.strip
          safe_foto = if foto_raw.match?(%r{\Ahttps?://}i) || foto_raw.start_with?('/')
                        foto_raw.truncate(500)
                      else
                        ''
                      end

          {
            'id'           => t[:id].to_s.to_i,
            'rating'       => t[:rating].to_s.to_i.clamp(1, 5),
            'nome'         => ActionController::Base.helpers.sanitize(t[:nome].to_s.strip, tags: []).truncate(100),
            'servico'      => ActionController::Base.helpers.sanitize(t[:servico].to_s.strip, tags: []).truncate(100),
            'foto'         => safe_foto,
            'texto'        => ActionController::Base.helpers.sanitize(t[:texto].to_s.strip, tags: []).truncate(500),
            'data'         => t[:data].to_s.strip.truncate(50),
            'comment'      => ActionController::Base.helpers.sanitize(t[:comment].to_s.strip, tags: []).truncate(500),
            'created_at'   => t[:created_at].to_s.strip.truncate(50),
            'exibirNaHome' => t[:exibirNaHome] == true || t[:exibirNaHome] == 'true'
          }
        end
        @establishment.assign_attributes(est_params.except(:public_settings, :legal_pages))
        @establishment.testimonials = raw_testimonials
      else
        @establishment.assign_attributes(est_params.except(:public_settings, :legal_pages))
      end

      # 🔒 SEGURANÇA: Merge não-destrutivo de public_settings (preserva chaves e configurações anteriores)
      if est_params[:public_settings].present?
        current_settings = @establishment.public_settings || {}
        merged_settings = current_settings.deep_merge(est_params[:public_settings].to_h.deep_stringify_keys)
        @establishment.public_settings = merged_settings
      end

      # 🔒 SEGURANÇA: Sanitização e validação de chaves para Páginas Legais (Stored XSS)
      if params.dig(:establishment, :legal_pages).present?
        raw_pages = params[:establishment][:legal_pages]
        sanitized_pages = {}
        Establishment::ALLOWED_LEGAL_PAGES.each do |page_key|
          val = raw_pages[page_key]
          next if val.nil?

          sanitized_pages[page_key] = ActionController::Base.helpers.sanitize(
            val.to_s,
            tags: Establishment::LEGAL_PAGE_ALLOWED_TAGS,
            attributes: Establishment::LEGAL_PAGE_ALLOWED_ATTRIBUTES
          ).to_s.strip.truncate(Establishment::LEGAL_PAGE_MAX_LENGTH)
        end
        @establishment.legal_pages = (@establishment.legal_pages || {}).merge(sanitized_pages)
      end

      @establishment.save!

      # Registra alteração de Páginas Legais no AuditLog para conformidade LGPD
      if params.dig(:establishment, :legal_pages).present?
        updated_keys = params[:establishment][:legal_pages].keys.map(&:to_s) & Establishment::ALLOWED_LEGAL_PAGES
        AuditLogger.log(
          action: 'update_legal_pages',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          establishment: @establishment,
          details: { pages_updated: updated_keys }
        )
      end

      # 🔒 AUDITORIA: Registra alteração de aparência visual (tema) no AuditLog
      if params.dig(:establishment, :public_settings, :theme).present?
        AuditLogger.log(
          action: 'update_theme_appearance',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          establishment: @establishment,
          details: { updated_by_role: current_user.role }
        )
      end

      if params[:address].present?
        address = @establishment.address || @establishment.build_address
        address.update!(address_params)
      end
    end

    @establishment.reload

    render json: {
      message: 'Configurações salvas com sucesso',
      establishment: serialized_establishment(@establishment)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  def upload_logo
    if params[:file].blank?
      render json: { error: 'Arquivo não enviado.' }, status: :unprocessable_entity
      return
    end

    old_path = @establishment.logo

    path = save_uploaded_file(params[:file], 'logo', @establishment.id)
    @establishment.update!(logo: path)

    delete_file_if_exists(old_path) if old_path.present? && old_path != path

    render json: {
      message: 'Logo enviada com sucesso',
      path: path,
      logo: path
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[Admin::Establishments#upload_logo] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao enviar logo.' }, status: :unprocessable_entity
  end

  def upload_banner
    if params[:file].blank?
      render json: { error: 'Arquivo não enviado.' }, status: :unprocessable_entity
      return
    end

    old_path = @establishment.banner

    path = save_uploaded_file(params[:file], 'banner', @establishment.id)
    @establishment.update!(banner: path)

    delete_file_if_exists(old_path) if old_path.present? && old_path != path

    render json: {
      message: 'Capa enviada com sucesso',
      path: path,
      banner: path
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[Admin::Establishments#upload_banner] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao enviar capa.' }, status: :unprocessable_entity
  end

  private

  def establishment_params
    params.require(:establishment).permit(
      :name,
      :description,
      :phone,
      :whatsapp,
      :email,
      :category,
      :instagram,
      :facebook,
      :booking_mode,
      amenities: [],
      payment_methods: [],
      public_settings: [
        :horarios_texto,
        theme: [
          :logoColor, :buttonBg, :buttonHover, :iconColor, :fontFamily, :fontSize,
          :backgroundLight, :textLight, :navbarLight, :cardLight,
          :backgroundDark, :textDark, :navbarDark, :cardDark
        ]
      ],
      legal_pages: [
        :privacy_policy,
        :terms_of_use,
        :cookie_policy,
        :about_us,
        :faq,
        :contact_info
      ],
      testimonials: [
        :id, :rating, :nome, :servico, :foto, :texto, :data, :comment, :created_at, :exibirNaHome
      ]
    )
  end

  def address_params
    params.require(:address).permit(
      :street,
      :number,
      :neighborhood,
      :city,
      :state,
      :zip_code,
      :complement,
      :country,
      :latitude,
      :longitude
    )
  end

  def valid_settings_input?(input)
    return false unless input.is_a?(ActionController::Parameters)

    %i[public_settings legal_pages].each do |key|
      return false if input.key?(key) && !input[key].is_a?(ActionController::Parameters)
    end
    settings = input[:public_settings]
    if settings&.key?(:theme)
      return false unless settings[:theme].is_a?(ActionController::Parameters)
    end
    if settings&.key?(:horarios_texto)
      return false unless settings[:horarios_texto].is_a?(String) && settings[:horarios_texto].length <= 100
    end
    %i[amenities payment_methods].each do |key|
      next unless input.key?(key)
      values = input[key]
      return false unless values.is_a?(Array) && values.size <= 50
      return false unless values.all? { |value| value.is_a?(String) && value.length <= 100 }
    end
    if input.key?(:testimonials)
      values = input[:testimonials]
      return false unless values.is_a?(Array) && values.size <= 100
      return false unless values.all? do |value|
        value.is_a?(ActionController::Parameters) && value.values.all? do |field|
          field.nil? || field == true || field == false || field.is_a?(Numeric) || field.is_a?(String)
        end
      end
    end
    true
  end

  def serialized_establishment(establishment)
    {
      id: establishment.id,
      name: establishment.name,
      slug: establishment.slug,
      description: establishment.description,
      logo: establishment.logo,
      banner: establishment.banner,
      phone: establishment.phone,
      whatsapp: establishment.whatsapp,
      email: establishment.email,
      category: establishment.category,
      instagram: establishment.instagram,
      facebook: establishment.facebook,
      amenities: establishment.amenities || [],
      payment_methods: establishment.payment_methods || [],
      booking_mode: establishment.booking_mode,
      testimonials: establishment.testimonials || [],
      public_settings: establishment.public_settings || {},
      legal_pages: can_manage_establishment? ? (establishment.legal_pages || {}) : {},
      can_edit_owner_settings: establishment_owner?,
      address: establishment.address ? {
        street: establishment.address.street,
        number: establishment.address.number,
        neighborhood: establishment.address.neighborhood,
        city: establishment.address.city,
        state: establishment.address.state,
        zip_code: establishment.address.zip_code,
        complement: establishment.address.complement,
        country: establishment.address.country
      } : nil,
      permissions: establishment_owner? ? {
        can_view_only_own_clients: false,
        can_manage_schedule: true,
        can_manage_services: true,
        can_manage_financial: true,
        can_manage_team: true,
        can_manage_establishment: true,
        can_manage_stock: true
      } : {
        can_view_only_own_clients: current_membership&.can_view_only_own_clients?,
        can_manage_schedule: current_membership&.can_manage_schedule?,
        can_manage_services: current_membership&.can_manage_services?,
        can_manage_financial: current_membership&.can_manage_financial?,
        can_manage_team: current_membership&.can_manage_team?,
        can_manage_establishment: current_membership&.can_manage_establishment?,
        can_manage_stock: current_membership&.can_manage_stock?
      }
    }
  end

  def establishment_owner?
    return true if current_user&.super_admin?
    return true if @establishment.present? && @establishment.owner_id == current_user&.id

    false
  end

  def can_manage_establishment?
    establishment_owner? || current_membership&.can_manage_establishment?
  end

  def save_uploaded_file(file, prefix, establishment_id)
    # 1. Limite de tamanho (5MB)
    if file.size > 5.megabytes
      raise StandardError, 'Arquivo muito grande. Limite de 5MB.'
    end

    # 2. Verificação de tipo real (Whitelist: JPEG, PNG, WEBP - SVG Bloqueado)
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

    safe_prefix = prefix.to_s.gsub(/[^a-zA-Z0-9_-]/, '')
    safe_establishment_id = establishment_id.to_i

    filename = "#{safe_prefix}_#{safe_establishment_id}_#{SecureRandom.uuid}#{extension}"

    upload_dir = Rails.root.join('public', 'uploads', 'establishments')
    FileUtils.mkdir_p(upload_dir)

    file_path = upload_dir.join(filename)

    # Decodifica e reencoda a imagem antes de torná-la pública. Isso impede que
    # um arquivo poliglota mantenha conteúdo arbitrário e limita imagens que
    # poderiam consumir memória excessiva ao serem processadas.
    data = file.read
    image = Vips::Image.new_from_buffer(data, '', access: :sequential)
    pixel_count = image.width.to_i * image.height.to_i
    raise StandardError, 'Dimensões da imagem excedem o limite permitido.' if image.width > 5000 || image.height > 5000 || pixel_count > 25_000_000

    options = detected_type == 'image/png' ? { compression: 6, strip: true } : { Q: 85, strip: true }
    image.write_to_file(file_path.to_s, **options)

    "/uploads/establishments/#{filename}"
  end

  def delete_file_if_exists(relative_path)
    # Só apaga arquivos gerados para o estabelecimento autenticado, sem segmentos de diretório livres.
    pattern = %r{\A/uploads/establishments/(?:logo|banner)_#{@establishment.id.to_i}_[0-9a-f-]{36}\.(?:jpg|png|webp)\z}
    return unless relative_path.to_s.match?(pattern)

    full_path = Rails.root.join('public', 'uploads', 'establishments', File.basename(relative_path))
    File.delete(full_path) if File.file?(full_path) && !File.symlink?(full_path)
  end
end
