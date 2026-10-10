# Completa o desafio real da API usando o código do job de e-mail em modo test.
# Os testes de entrega também renderizam a mensagem e verificam o destinatário.
module EmailLoginTestHelper
  include ActiveJob::TestHelper

  def login_with_email_verification(path, params:, headers: {})
    post path, params: params, headers: headers, as: :json
    if response.successful? && response.parsed_body['requires_verification']
      job = enqueued_jobs.reverse.find do |entry|
        entry[:args].first(2) == ['SecurityAlertMailer', 'login_verification_code']
      end
      arguments = ActiveJob::Arguments.deserialize(job.fetch(:args))
      code = arguments.last.fetch(:args).first.fetch(:otp_code)
      post path, params: params.merge(otp_code: code), headers: headers, as: :json
    end
  end
end
