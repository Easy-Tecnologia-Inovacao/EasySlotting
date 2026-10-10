module StaffRecoveryCookie
  private

  def staff_recovery_payload
    raw = cookies.encrypted[StaffSessionRecovery::COOKIE_NAME]
    JSON.parse(raw) if raw.is_a?(String)
  rescue JSON::ParserError
    nil
  end

  def write_staff_recovery_cookie(payload)
    # Cookie de sessão, sem Domain: host restrito e sem login persistente extra.
    cookies.encrypted[StaffSessionRecovery::COOKIE_NAME] = {
      value: payload.to_json, httponly: true, same_site: :strict,
      secure: Rails.env.production? || request.ssl?, path: StaffSessionRecovery::COOKIE_PATH
    }
  end

  def delete_staff_recovery_cookie
    cookies.delete(StaffSessionRecovery::COOKIE_NAME,
      path: StaffSessionRecovery::COOKIE_PATH, secure: Rails.env.production? || request.ssl?, same_site: :strict)
  end
end
