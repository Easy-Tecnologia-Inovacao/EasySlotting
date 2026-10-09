class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :establishment, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true

  # Princípio WORM: Impede alterações após criação
  def readonly?
    !new_record?
  end

  # Bloqueia exclusões de registros de auditoria
  before_destroy { throw :abort }
end

