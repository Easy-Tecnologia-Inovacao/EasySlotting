require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test 'health endpoint is available without authentication' do
    get '/up'
    assert_response :success
    assert_equal 'text/html', response.media_type
  end
end
