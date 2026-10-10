# Recupera uma sessão DTA existente; nunca cria outro client nem aumenta a quota.
# O segredo fica apenas no cookie criptografado. O banco guarda somente hashes.
class StaffSessionRecovery
  class InvalidSession < StandardError; end
  class InvalidCsrf < StandardError; end

  COOKIE_NAME = 'staff_session_recovery'.freeze
  COOKIE_PATH = '/api/devise_users'.freeze
  SECRET_FORMAT = /\A[a-f0-9]{64}\z/

  def self.issue!(user, client)
    secret = SecureRandom.hex(32)
    csrf = SecureRandom.hex(32)
    user.with_lock do
      entry = user.tokens[client]
      raise InvalidSession unless entry && user.active_for_authentication? &&
        %w[owner employee super_admin].include?(user.role)
      entry['recovery_digest'] = Digest::SHA256.hexdigest(secret)
      entry['recovery_csrf_digest'] = Digest::SHA256.hexdigest(csrf)
      user.save!
    end
    [{ 'user_id' => user.id, 'client' => client, 'secret' => secret }, csrf]
  end

  def initialize(payload, client:, uid:, csrf:)
    @payload, @client, @uid, @csrf = payload, client, uid, csrf
  end

  def restore!
    with_session do |user|
      [user, user.create_new_auth_token(@client)]
    end
  end

  def revoke!
    with_session do |user|
      user.tokens.delete(@client)
      user.save!
      user
    end
  end

  private

  def with_session
    unless @payload.is_a?(Hash) && @payload['user_id'].is_a?(Integer) &&
           @client.is_a?(String) && @client.bytesize.between?(1, 128) &&
           @uid.is_a?(String) && @uid.bytesize.between?(1, 254) &&
           @payload['client'] == @client && @payload['secret'].is_a?(String) &&
           @payload['secret'].match?(SECRET_FORMAT)
      raise InvalidSession
    end
    user = User.find_by(id: @payload['user_id'])
    raise InvalidSession unless user

    result = user.with_lock do
      unless %w[owner employee super_admin].include?(user.role) &&
             user.active_for_authentication? && user.uid == @uid
        next InvalidSession.new
      end
      # A mesma regra de expiração/downgrade aplicada aos access tokens.
      permitted = OwnerSessionPolicy.new(user).permitted_tokens
      user.update_columns(tokens: permitted) if user.tokens != permitted
      entry = permitted[@client]
      next InvalidSession.new unless entry && matches_digest?(entry['recovery_digest'], @payload['secret'])
      unless @csrf.is_a?(String) && @csrf.match?(SECRET_FORMAT) &&
             matches_digest?(entry['recovery_csrf_digest'], @csrf)
        next InvalidCsrf.new
      end
      yield user
    end
    # A negativa não desfaz a poda definitiva de sessões excedentes/expiradas.
    raise result if result.is_a?(StandardError)
    result
  end

  def matches_digest?(stored, value)
    stored.is_a?(String) && stored.match?(SECRET_FORMAT) &&
      ActiveSupport::SecurityUtils.secure_compare(stored, Digest::SHA256.hexdigest(value))
  end
end
