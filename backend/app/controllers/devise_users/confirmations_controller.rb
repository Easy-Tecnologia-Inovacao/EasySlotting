# app/controllers/devise_users/confirmations_controller.rb
class DeviseUsers::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  protected

  # O DTA chama este método e faz `permit` aqui dentro.
  # Inclua os extras para não gerar o aviso de "Unpermitted".
  def resource_params
    params.permit(:confirmation_token, :redirect_url, :config)
  end
end