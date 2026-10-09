# config/initializers/content_security_policy.rb
#
# Esta aplicação é uma API JSON — a CSP aqui protege as respostas HTML
# de erro geradas pelo Rails (ex: páginas de exceção em desenvolvimento).
# O frontend Vue.js deve ter sua própria CSP configurada via headers do servidor.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src  :none
    policy.script_src   :self
    policy.style_src    :self, 'unsafe-inline', 'https://fonts.googleapis.com', 'https://cdn.jsdelivr.net'
    policy.img_src      :self, :data, :https, :blob
    policy.font_src     :self, 'https://fonts.gstatic.com', 'https://cdn.jsdelivr.net'
    policy.connect_src  :self, :https, :wss, :ws  # wss/ws necessários para ActionCable em /cable
    policy.frame_ancestors :none
    policy.object_src   :none
    policy.base_uri     :self
    policy.form_action  :self
    policy.report_uri   '/csp-violation-report' if Rails.env.production?

    policy.upgrade_insecure_requests if Rails.env.production?
  end

  if Rails.env.development?
    config.content_security_policy_report_only = true
  end
end
