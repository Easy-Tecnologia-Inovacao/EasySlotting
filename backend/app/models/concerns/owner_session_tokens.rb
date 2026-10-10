# O nome é mantido por compatibilidade; aplica a quota a todas as roles staff.
# A gem define create_token diretamente na classe no included. prepend mantém
# essa implementação original na cadeia de super, sem copiá-la para o projeto.
module OwnerSessionTokens
  def create_token(client: nil, lifespan: nil, cost: nil, **extras)
    return super unless owner? || employee? || super_admin?

    with_lock do
      policy = OwnerSessionPolicy.new(self)
      policy.prepare!(client: client, device_digest: extras[:device_digest])
      previous = (tokens[client] || {}).slice(*OwnerSessionPolicy::METADATA_KEYS,
                                            'recovery_digest', 'recovery_csrf_digest')
      metadata = previous.merge('issued_at' => previous['issued_at'] || Time.current.to_f,
                                'last_seen_at' => Time.current.to_i)
      token = super(client: client, lifespan: lifespan, cost: cost, **extras.merge(metadata))
      save!
      token
    end
  end

  # Engloba a leitura do token anterior e o save final feitos pela gem.
  def create_new_auth_token(client = nil)
    return super unless owner? || employee? || super_admin?

    with_lock { super }
  end
end
