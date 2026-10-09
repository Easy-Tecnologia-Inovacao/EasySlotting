# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :password, :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :otp_code, :verification_code,
  :ssn, :cpf, :cnpj, :cvv, :cvc, :credit_card, :card_number, :expiration, :access_token, :refresh_token,
  :pix_key, :amount, :price, :total_amount, :service_amount, :products_amount
]
