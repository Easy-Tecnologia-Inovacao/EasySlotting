# Idempotent bootstrap for staging/production. Never truncate or reset accounts.
ActiveRecord::Base.transaction do
  Plan.create_with(
    name: 'Plano Mensal',
    description: 'Plano mensal de agendamento.',
    price: 49.90,
    duration_months: 1,
    active: true,
    highlight: false
  ).find_or_create_by!(code: 'monthly')

  admin_email = ENV['BOOTSTRAP_ADMIN_EMAIL'].to_s.strip.downcase
  admin_password = ENV['BOOTSTRAP_ADMIN_PASSWORD'].to_s
  if admin_email.present? || admin_password.present?
    raise 'Provide both BOOTSTRAP_ADMIN_EMAIL and BOOTSTRAP_ADMIN_PASSWORD' if admin_email.blank? || admin_password.blank?

    admin = User.find_or_initialize_by(email: admin_email)
    if admin.new_record?
      if User.exists?(role: 'super_admin')
        raise 'A super admin already exists; use that account instead of creating another bootstrap administrator'
      end
      admin.assign_attributes(
        name: 'Administrador', role: 'super_admin', provider: 'email', uid: admin_email,
        active: true, password: admin_password, password_confirmation: admin_password
      )
      admin.save!
    elsif !admin.super_admin?
      raise 'Bootstrap email already belongs to a non-administrator account'
    end
  end
end
