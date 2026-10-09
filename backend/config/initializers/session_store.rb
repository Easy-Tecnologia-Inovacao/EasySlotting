# Configuração de sessões movida de application.rb para melhor organização.
# Cookies httpOnly, secure em produção, same_site lax.
Rails.application.config.session_store :cookie_store,
  key: '_agendamento_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
