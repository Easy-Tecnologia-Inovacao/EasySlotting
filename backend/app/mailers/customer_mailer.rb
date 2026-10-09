class CustomerMailer < ApplicationMailer

  def password_reset(customer, reset_url)
    @customer = customer
    @reset_url = reset_url
    @establishment_name = customer.establishment&.name || 'EasySloting'

    mail(
      to: @customer.email,
      subject: "Redefinição de senha - #{@establishment_name}"
    )
  end

  def account_invitation(customer, establishment)
    @customer = customer
    @establishment = establishment
    @slug = establishment.slug

    mail(
      to: @customer.email,
      subject: "Crie sua conta em #{establishment.name} - EasySloting"
    )
  end
end
