# Limite por conta staff: owner/funcionário pelo plano; super admin tem cinco.
# A emissão deve usar o lock da conta, não um contador controlado pelo navegador.
class OwnerSessionPolicy
  DEFAULT_LIMIT = 1
  MAX_LIMIT = 4
  SUPER_ADMIN_LIMIT = 5
  METADATA_KEYS = %w[issued_at device_digest ua ip name last_seen_at].freeze

  class LimitReached < StandardError
    attr_reader :limit

    def initialize(limit)
      @limit = limit
      super('Limite de sessões simultâneas atingido.')
    end
  end

  class SessionUnavailable < StandardError; end

  def initialize(user)
    @user = user
  end

  def limit
    @limit ||= begin
      return SUPER_ADMIN_LIMIT if @user.super_admin?
      # Uma faixa do catálogo por empresa, sem somar planos ou renovações.
      # Seleciona a última iniciada antes de verificar a validade: um contrato
      # substituído não pode reaparecer quando sua substituta vencer.
      subscriptions = Subscription.where(establishment_id: entitled_establishments.select(:id))
        .started
        .select('DISTINCT ON (subscriptions.establishment_id) subscriptions.*')
        .order(:establishment_id, created_at: :desc, id: :desc)
        .includes(:plan)

      configured = subscriptions.filter_map do |subscription|
        subscription.plan.max_owner_sessions if subscription.active?
      end.max
      (configured || DEFAULT_LIMIT).clamp(DEFAULT_LIMIT, MAX_LIMIT)
    end
  end

  private def entitled_establishments
    if @user.employee?
      # O vínculo precisa estar ativo. Nunca utilizar owner/empresa do payload.
      linked_owners = Establishment.where(active: true)
        .where(id: @user.establishment_memberships.where(active: true, role: 'employee').select(:establishment_id))
        .select(:owner_id)
      Establishment.where(active: true, owner_id: User.where(role: 'owner', active: true, id: linked_owners).select(:id))
    else
      @user.owned_establishments.where(active: true)
    end
  end

  def active_tokens
    (@user.tokens || {}).select do |_client, data|
      data.is_a?(Hash) && data['expiry'].to_i > Time.current.to_i
    end
  end

  def permitted_tokens
    # Em downgrade, preserva as sessões mais recentemente criadas. issued_at
    # nunca muda na rotação; legados sem essa data têm desempate estável por ID.
    active_tokens.sort_by { |client, data| [-data['issued_at'].to_f, client] }
      .first(limit).to_h
  end

  # Chamado somente enquanto User está sob with_lock.
  def prepare!(client:, device_digest: nil)
    permitted = permitted_tokens
    if client.present?
      raise SessionUnavailable unless permitted.key?(client)
    else
      # Novo login já passou por senha/OTP. Substitui a sessão do mesmo
      # navegador, revogando a anterior; o identificador não autentica ninguém.
      if device_digest.is_a?(String) && device_digest.match?(/\A[a-f0-9]{64}\z/)
        permitted = permitted.reject { |_id, data| data['device_digest'] == device_digest }
      end
      raise LimitReached, limit if permitted.size >= limit
    end
    @user.tokens = permitted
  end
end
