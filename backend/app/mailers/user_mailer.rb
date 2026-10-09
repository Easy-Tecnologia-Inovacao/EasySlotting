class UserMailer < ApplicationMailer

  def employee_created(user, password)
    @user = user
    @password = password

    mail(
      to: @user.email,
      subject: 'Sua conta foi criada - EasySlotting'
    )
  end
end