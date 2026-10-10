require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test 'active catalog has one plan per session tier and inactive history cannot be reactivated into an occupied tier' do
    plans = (1..4).map do |limit|
      Plan.create!(name: "Faixa #{limit}", code: "tier_#{SecureRandom.hex(4)}", price: limit * 50,
        duration_months: 1, max_owner_sessions: limit, active: true)
    end
    archived = Plan.create!(name: 'Plano anterior', code: "archive_#{SecureRandom.hex(4)}", price: 50,
      duration_months: 1, max_owner_sessions: 4, active: false)
    archived.active = true
    assert_not archived.valid?
    assert archived.errors[:max_owner_sessions].present?
    plans.first.update!(name: 'Standard')
    assert_equal 4, Plan.where(active: true).count
    archived.price = 250
    plans.last.update!(active: false)
    assert archived.save!, archived.errors.full_messages.to_sentence
    assert_equal 4, Plan.where(active: true).count
    assert_equal 4, plans.last.reload.max_owner_sessions
  end

  test 'database rejects duplicate active tiers even when model validation is bypassed' do
    Plan.create!(name: 'Plus', code: "plus_#{SecureRandom.hex(4)}", price: 100, duration_months: 1, max_owner_sessions: 2)
    duplicate = Plan.new(name: 'Plus repetido', code: "duplicate_#{SecureRandom.hex(4)}", price: 150,
      duration_months: 1, max_owner_sessions: 2)
    assert_raises(ActiveRecord::RecordNotUnique) do
      Plan.transaction(requires_new: true) { duplicate.save!(validate: false) }
    end
  end

  test 'owner session limit is mandatory and accepts only integers between one and four' do
    plan = Plan.new(name: 'Plano Sessões', code: "sessions_#{SecureRandom.hex(4)}", price: 100, duration_months: 1)
    assert_equal 1, plan.max_owner_sessions
    [nil, 0, 5, -1, 2.5, '4invalid'].each do |invalid|
      plan.max_owner_sessions = invalid
      assert_not plan.valid?
      assert plan.errors[:max_owner_sessions].present?
    end
    (1..4).each do |limit|
      plan.max_owner_sessions = limit
      assert plan.valid?, plan.errors.full_messages.to_sentence
    end
    plan.save!
    assert_raises(ActiveRecord::StatementInvalid) do
      Plan.transaction(requires_new: true) { plan.update_column(:max_owner_sessions, 5) }
    end
  end

  test "valida que preço promocional deve ser menor que o preço normal quando promoção está ativa" do
    plan = Plan.new(
      name: "Plano Teste",
      code: "plano_teste_#{SecureRandom.hex(4)}",
      price: 100.0,
      duration_months: 1,
      promotion_active: true,
      promotional_price: 150.0
    )
    assert_not plan.valid?
    assert_includes plan.errors[:promotional_price], "deve ser estritamente menor que o preço normal do plano"
  end

  test "permite preço promocional menor que o preço normal" do
    plan = Plan.new(
      name: "Plano Teste Válido",
      code: "plano_valido_#{SecureRandom.hex(4)}",
      price: 100.0,
      duration_months: 1,
      promotion_active: true,
      promotional_price: 80.0,
      promotion_starts_at: Time.current,
      promotion_duration_days: 30
    )
    assert plan.valid?, plan.errors.full_messages.to_sentence
  end

  test "impede alteração do código do plano se já houver assinaturas vinculadas" do
    suffix = SecureRandom.hex(4)
    plan = Plan.create!(
      name: "Plano Com Assinatura",
      code: "plano_sub_#{suffix}",
      price: 99.0,
      duration_months: 1
    )

    user = User.create!(
      name: "Dono Teste",
      email: "dono-#{suffix}@test.com",
      password: "Seguranca#2026",
      role: "owner",
      confirmed_at: Time.current,
      uid: "dono-#{suffix}@test.com",
      provider: "email"
    )
    est = Establishment.create!(
      name: "Estabelecimento Teste",
      slug: "estab-#{suffix}",
      email: "estab-#{suffix}@test.com",
      owner: user
    )
    est.subscriptions.create!(
      plan: plan,
      status: "active",
      start_date: Date.current,
      end_date: 1.month.from_now,
      billing_cycle: "monthly",
      price_paid: 99.0
    )

    plan.code = "novo_codigo_alterado"
    assert_not plan.valid?
    assert_includes plan.errors[:code], "não pode ser alterado pois já existem assinaturas vinculadas a este plano"
  end

  test "permite alteração do código do plano se não houver assinaturas vinculadas" do
    plan = Plan.create!(
      name: "Plano Sem Assinatura",
      code: "plano_sem_sub_#{SecureRandom.hex(4)}",
      price: 49.0,
      duration_months: 1
    )

    plan.code = "plano_codigo_novo"
    assert plan.valid?, plan.errors.full_messages.to_sentence
    assert plan.save!
    assert_equal "plano_codigo_novo", plan.reload.code
  end
end
