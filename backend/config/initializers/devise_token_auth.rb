# frozen_string_literal: true

DeviseTokenAuth.setup do |config|
  # Tokens são rotacionados a cada request (mais seguro)
  config.change_headers_on_each_request = true

  # Tokens expiram após 2 horas de inatividade (rotacionados a cada request)
  config.token_lifespan = 2.hours

  # Custo bcrypt para hashing de tokens (10 é seguro para produção)
  config.token_cost = Rails.env.test? ? 4 : 10

  # Máximo de 5 dispositivos simultâneos por usuário
  config.max_number_of_devices = 5

  # Buffer de 5 segundos para requests em lote
  config.batch_request_buffer_throttle = 5.seconds

  # Exige senha atual para alterações de senha
  config.check_current_password_before_update = :password
end
