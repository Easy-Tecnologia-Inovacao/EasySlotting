# test/services_security_test.rb
require_relative "../config/environment"
require "minitest/autorun"
require "securerandom"

class ServicesSecurityTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # 1. Criar proprietário e estabelecimento A
    @owner_a = User.create!(
      name: "Dono A",
      email: "owner-a-#{suffix}@test.com",
      password: "Seguranca#2026",
      role: "owner",
      confirmed_at: Time.current,
      uid: "owner-a-#{suffix}@test.com",
      provider: "email"
    )
    @est_a = Establishment.create!(name: "Est A", slug: "est-a-#{suffix}", email: "a-#{suffix}@test.com", owner: @owner_a)
    EstablishmentMembership.create!(establishment: @est_a, user: @owner_a, role: 'owner')

    # 2. Criar funcionário A (com permissão de serviços)
    @emp_a = User.create!(
      name: "Func A",
      email: "emp-a-#{suffix}@test.com",
      password: "Seguranca#2026",
      role: "employee",
      confirmed_at: Time.current,
      uid: "emp-a-#{suffix}@test.com",
      provider: "email"
    )
    EstablishmentMembership.create!(
      establishment: @est_a,
      user: @emp_a,
      role: 'employee',
      can_manage_services: true
    )

    # 3. Criar funcionário B (sem permissão de serviços ou de outro estabelecimento)
    @emp_b = User.create!(
      name: "Func B",
      email: "emp-b-#{suffix}@test.com",
      password: "Seguranca#2026",
      role: "employee",
      confirmed_at: Time.current,
      uid: "emp-b-#{suffix}@test.com",
      provider: "email"
    )
    # Estabelecimento B
    @est_b = Establishment.create!(name: "Est B", slug: "est-b-#{suffix}", email: "b-#{suffix}@test.com", owner: @owner_a)
    EstablishmentMembership.create!(
      establishment: @est_b,
      user: @emp_b,
      role: 'employee',
      can_manage_services: true
    )
  end

  def test_service_validations
    # Serviço inválido por preço negativo
    service = @est_a.services.new(name: "Corte", price: -10, duration_minutes: 30, service_type: "Cabelo")
    assert_not service.valid?, "Serviço com preço negativo deveria ser inválido"

    # Serviço inválido por nome vazio ou muito longo
    service2 = @est_a.services.new(name: "", price: 50.0, duration_minutes: 30, service_type: "Cabelo")
    assert_not service2.valid?, "Serviço com nome em branco deveria ser inválido"

    service3 = @est_a.services.new(name: "A" * 101, price: 50.0, duration_minutes: 30, service_type: "Cabelo")
    assert_not service3.valid?, "Serviço com nome maior que 100 caracteres deveria ser inválido"
  end

  def test_service_soft_delete
    service = @est_a.services.create!(name: "Corte", price: 50.0, duration_minutes: 30, service_type: "Cabelo")
    assert_equal 1, @est_a.services.count

    # Descarta (Soft Delete)
    service.discard
    assert_not_nil service.deleted_at

    # Verifica que não aparece na query padrão
    assert_equal 0, @est_a.services.count
    # Mas aparece em with_deleted
    assert_equal 1, Service.with_deleted.where(id: service.id).count
  end

  def test_service_policy_owner_vs_employee
    service = @est_a.services.create!(name: "Corte", price: 50.0, duration_minutes: 30, service_type: "Cabelo")

    # Vincula o funcionário A ao serviço
    service.employees << @emp_a

    # Owner tem permissão completa
    policy_owner = ServicePolicy.new(@owner_a, service, @est_a)
    assert policy_owner.create?
    assert policy_owner.update?
    assert policy_owner.destroy?

    # Func A tem permissão porque está associado ao serviço
    policy_emp_a = ServicePolicy.new(@emp_a, service, @est_a)
    assert policy_emp_a.create?
    assert policy_emp_a.update?
    assert policy_emp_a.destroy?

    # Func B não tem permissão para atualizar/deletar serviço de outro estabelecimento
    policy_emp_b = ServicePolicy.new(@emp_b, service, @est_a)
    assert_not policy_emp_b.update?, "Funcionário de outro estabelecimento não deve poder atualizar serviço"
    assert_not policy_emp_b.destroy?, "Funcionário de outro estabelecimento não deve poder deletar serviço"
  end

  def test_service_package_policy
    service = @est_a.services.create!(name: "Massagem", price: 80.0, duration_minutes: 60, service_type: "Fisio")
    
    # Pacote do funcionário A
    package_a = @est_a.service_packages.create!(
      name: "Pacote A",
      price: 300.0,
      duration_minutes: 60,
      service_id: service.id,
      sessions_total: 4,
      user_id: @emp_a.id
    )

    # Owner tem acesso completo
    policy_owner = ServicePackagePolicy.new(@owner_a, package_a, @est_a)
    assert policy_owner.update?
    assert policy_owner.destroy?

    # Func A tem acesso completo porque o pacote é dele
    policy_emp_a = ServicePackagePolicy.new(@emp_a, package_a, @est_a)
    assert policy_emp_a.update?
    assert policy_emp_a.destroy?

    # Func B não tem acesso porque o pacote não é dele
    policy_emp_b = ServicePackagePolicy.new(@emp_b, package_a, @est_a)
    assert_not policy_emp_b.update?, "Funcionário não deve poder atualizar pacote de outro funcionário"
    assert_not policy_emp_b.destroy?, "Funcionário não deve poder deletar pacote de outro funcionário"
  end

  def test_audit_logging_generation
    service = @est_a.services.create!(name: "Barba", price: 30.0, duration_minutes: 20, service_type: "Barbearia")
    
    # Simular auditoria
    log = AuditLog.create!(
      user: @owner_a,
      establishment: @est_a,
      action: 'create_service',
      auditable: service,
      ip_address: '127.0.0.1',
      details: { name: service.name }
    )

    assert_equal 'create_service', log.action
    assert_equal @owner_a.id, log.user_id
    assert_equal @est_a.id, log.establishment_id
    assert_equal service.id, log.auditable_id
  end
end
