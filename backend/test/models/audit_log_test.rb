require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "cria registro de auditoria com sucesso" do
    log = AuditLog.create!(
      action: "test_action",
      ip_address: "127.0.0.1",
      details: { foo: "bar" }
    )
    assert log.persisted?
    assert_equal "test_action", log.action
  end

  test "impede atualização de registro de auditoria existente (princípio WORM)" do
    log = AuditLog.create!(
      action: "original_action",
      ip_address: "127.0.0.1"
    )

    assert_raises ActiveRecord::ReadOnlyRecord do
      log.update!(action: "tampered_action")
    end
    assert_equal "original_action", log.reload.action
  end

  test "impede exclusão de registro de auditoria (princípio WORM)" do
    log = AuditLog.create!(
      action: "critical_action",
      ip_address: "127.0.0.1"
    )

    assert_no_difference "AuditLog.count" do
      result = log.destroy
      assert_equal false, result
    end
    assert log.persisted?
  end
end
