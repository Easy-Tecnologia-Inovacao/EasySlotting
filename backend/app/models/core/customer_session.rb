# Cada login possui credenciais próprias. Não há teto comercial de aparelhos.
# Guardar somente hashes; expiração e revogação são sempre verificadas no banco.
class CustomerSession < ApplicationRecord
  SESSION_ID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/.freeze
  belongs_to :customer

  validates :session_id, presence: true, uniqueness: true,
    format: { with: SESSION_ID_PATTERN }
  validates :refresh_token_digest, :csrf_token_digest,
    format: { with: /\A[0-9a-f]{64}\z/ }
  validates :expires_at, presence: true

  scope :active, -> { where('expires_at > ?', Time.current) }

  def refresh_matches?(raw_token)
    digest_matches?(refresh_token_digest, raw_token)
  end

  def csrf_matches?(raw_token)
    digest_matches?(csrf_token_digest, raw_token)
  end

  def as_json(*)
    # Evita serialização acidental de hashes ou da credencial de renovação.
    { session_id: session_id, created_at: created_at&.iso8601, expires_at: expires_at.iso8601 }
  end

  private

  def digest_matches?(stored, raw)
    raw.is_a?(String) && raw.bytesize.between?(1, 4096) &&
      ActiveSupport::SecurityUtils.secure_compare(stored, Digest::SHA256.hexdigest(raw))
  end
end
