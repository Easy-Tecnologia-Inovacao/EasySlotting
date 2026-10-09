class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('EMAIL_FROM', ENV.fetch('EMAIL_USER', 'noreply@example.test'))
  layout 'mailer'
end
