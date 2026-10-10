require_relative "boot"

require "rails/all"
require "devise"
require "devise/orm/active_record"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Agendamento
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # Fix: Active Storage queues config must be set before load_defaults
    config.active_storage.queues ||= ActiveSupport::InheritableOptions.new
    config.active_storage.queues.analysis = :active_storage_analysis
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Brasilia'
    config.i18n.default_locale = :'pt-BR'
    # Jobs de e-mail transportam OTP e links de recuperação; não registrar argumentos.
    config.active_job.log_arguments = false
    
    # Habilita cookies para API-only (necessário para httpOnly refresh token)
    config.middleware.use ActionDispatch::Cookies
    # Session store configurado em config/initializers/session_store.rb
    # Impede que o Rails converta colunas 'time' do PostgreSQL para UTC ao
    # salvar/ler. Sem isso, "11:00" seria salvo como "14:00" (UTC) e lido de
    # volta como "08:00" (local), causando erros no motor de agendamento.
    config.active_record.time_zone_aware_types = [:datetime]
    # config.eager_load_paths << Rails.root.join("extras")

    # Configuração de Headers de Segurança (OWASP Recomendado)
    config.action_dispatch.default_headers = {
      'X-Frame-Options'        => 'DENY',
      'X-Content-Type-Options' => 'nosniff',
      'X-XSS-Protection'       => '0',
      'Referrer-Policy'        => 'strict-origin-when-cross-origin',
      'Permissions-Policy'     => 'camera=(), microphone=(), geolocation=()'
    }
  end
end
