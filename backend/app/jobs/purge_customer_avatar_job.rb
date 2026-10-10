class PurgeCustomerAvatarJob < ApplicationJob
  retry_on SystemCallError, wait: :polynomially_longer, attempts: 5

  def perform(customer_id, relative_path)
    return unless relative_path.is_a?(String)

    # Só aceitar nomes gerados pelo upload para este cliente, sem traversal,
    # URL externa, subdiretório arbitrário ou avatar pertencente a outra conta.
    pattern = %r{\A/uploads/customers/(avatar_customer_#{Integer(customer_id)}_\d+_[a-f0-9]{8}\.(?:jpg|png|webp))\z}
    match = relative_path.match(pattern)
    return unless match

    directory = avatar_directory
    target = directory.join(match[1])
    return unless File.file?(target)
    return if File.symlink?(target) || File.symlink?(directory)
    return unless File.dirname(File.realpath(target)) == File.realpath(directory)

    File.delete(target)
  rescue Errno::ENOENT
    # Idempotente: outro job já pode ter removido o avatar.
    nil
  end

  private

  def avatar_directory
    Rails.root.join('public', 'uploads', 'customers')
  end
end
