class UserMailer < ApplicationMailer

  def employee_created(user, password)
    @user = user
    @password = password

    mail(
      to: @user.email,
      subject: 'Sua conta foi criada - EasySloting'
    )
  end
end