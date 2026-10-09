require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "valida que assinatura ativa responde corretamente aos métodos de estado" do
    suffix = SecureRandom.hex(4)
    user = User.create!(
      name: "Owner Sub Test",
      email: "owner-sub-#{suffix}@test.com",
      password: "Seguranca#2026",
      role: "owner",
      confirmed_at: Time.current,
      uid: "owner-sub-#{suffix}@test.com",
      provider: "email"
    )
    est = Establishment.create!(
      name: "Est Sub Test",
      slug: "est-sub-#{suffix}",
      email: "est-sub-#{suffix}@test.com",
      owner: user
    )
    plan = Plan.create!(
      name: "Plano Sub",
      code: "plano_sub_test_#{suffix}",
      price: 50.0,
      duration_months: 1,
      active: true
    )
    sub = est.subscriptions.create!(
      plan: plan,
      status: "active",
      start_date: Date.current,
      end_date: 1.month.from_now,
      billing_cycle: "monthly",
      price_paid: 50.0
    )

    assert sub.active?
    assert_not sub.expired?
  end
end
