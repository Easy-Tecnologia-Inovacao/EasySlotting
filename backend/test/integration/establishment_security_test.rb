require "test_helper"

class EstablishmentSecurityTest < ActionDispatch::IntegrationTest
  setup do
    suffix = SecureRandom.hex(6)
    @owner = User.create!(name: 'Dono Teste', email: "owner-#{suffix}@test.com",
                          password: 'Seguranca#2026', role: 'owner')
    @employee = User.create!(name: 'Funcionario Teste', email: "employee-#{suffix}@test.com",
                             password: 'Seguranca#2026', role: 'employee')
    @establishment = Establishment.create!(name: 'Empresa', slug: "empresa-#{suffix}", owner: @owner,
                                           legal_pages: { privacy_policy: '<p>Política atual</p>' })
    @membership = EstablishmentMembership.create!(establishment: @establishment, user: @employee,
                                                   role: 'employee', can_manage_establishment: true)
  end

  test 'employee cannot clear legal pages with an empty object' do
    update_as(@employee, legal_pages: {})
    assert_response :forbidden
    assert_equal '<p>Política atual</p>', @establishment.reload.legal_pages['privacy_policy']
  end

  test 'employee can update ordinary settings without owner fields' do
    update_as(@employee, description: 'Nova descrição')
    assert_response :success
    assert_equal 'Nova descrição', @establishment.reload.description
  end

  test 'employee without permission cannot write settings' do
    @membership.update!(can_manage_establishment: false)
    update_as(@employee, description: 'Não autorizado')
    assert_response :forbidden
  end

  test 'foreign establishment header is rejected' do
    foreign = Establishment.create!(name: 'Outra', slug: "outra-#{SecureRandom.hex(6)}", owner: @owner)
    put '/api/admin/establishment', params: { establishment: { description: 'Não autorizado' } },
        headers: @employee.create_new_auth_token.merge('X-Establishment-ID' => foreign.id.to_s), as: :json
    assert_response :forbidden
    assert_nil foreign.reload.description
  end

  test 'image paths cannot be assigned through general update' do
    update_as(@owner, logo: '/uploads/establishments/logo_999_other.jpg', banner: '/arbitrary.svg')
    assert_response :success
    assert_nil @establishment.reload.logo
    assert_nil @establishment.banner
  end

  test 'javascript and data links are rejected by the server' do
    ['javascript:alert(1)', 'data:text/html,test', '//example.com'].each do |url|
      update_as(@owner, facebook: url)
      assert_response :unprocessable_entity
    end
    update_as(@owner, facebook: 'https://facebook.com/empresa')
    assert_response :success
  end

  test 'invalid JSON shapes and excessive collections return validation errors' do
    [{ public_settings: { theme: [] } }, { testimonials: ['invalid'] },
     { amenities: ['a'] * 51 }, { public_settings: { horarios_texto: 123 } }].each do |input|
      update_as(@owner, input)
      assert_response :unprocessable_entity
    end
  end

  test 'upload rejects HTML even when the client claims it is a PNG' do
    Tempfile.create(['fake', '.png']) do |file|
      file.write('<html><script>alert(1)</script></html>')
      file.flush
      upload = Rack::Test::UploadedFile.new(file.path, 'image/png')
      post '/api/admin/establishment/upload_logo', params: { file: upload },
           headers: @owner.create_new_auth_token.merge('X-Establishment-ID' => @establishment.id.to_s)
      assert_response :unprocessable_entity
      assert_nil @establishment.reload.logo
    end
  end

  test 'file cleanup only deletes generated images belonging to this establishment' do
    controller = Admin::EstablishmentsController.new
    controller.instance_variable_set(:@establishment, @establishment)
    uuid = SecureRandom.uuid
    own_path = "/uploads/establishments/logo_#{@establishment.id}_#{uuid}.png"
    foreign_path = "/uploads/establishments/logo_#{@establishment.id + 1}_#{uuid}.png"
    own_file = Rails.root.join('public', own_path.delete_prefix('/'))
    foreign_file = Rails.root.join('public', foreign_path.delete_prefix('/'))
    FileUtils.mkdir_p(own_file.dirname)
    File.write(own_file, 'test')
    File.write(foreign_file, 'test')
    controller.send(:delete_file_if_exists, foreign_path)
    assert File.exist?(foreign_file)
    controller.send(:delete_file_if_exists, own_path)
    assert_not File.exist?(own_file)
  ensure
    [own_file, foreign_file].compact.each { |path| File.delete(path) if File.file?(path) }
  end

  private

  def update_as(user, attributes)
    put '/api/admin/establishment', params: { establishment: attributes },
        headers: user.create_new_auth_token.merge('X-Establishment-ID' => @establishment.id.to_s), as: :json
  end
end
