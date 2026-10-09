# test/password_security_test.rb
require_relative "../config/environment"
require "securerandom"

puts "\n========================================================"
puts "🔒 INICIANDO SUÍTE DE TESTES: SEGURANÇA E COMPLEXIDADE DE SENHA"
puts "========================================================\n"

def assert_invalid(record, field, error_substring)
  if record.valid?
    puts "❌ FALHA: #{record.class} deveria ser inválido, mas passou!"
    exit(1)
  elsif !record.errors[field].any? { |msg| msg.include?(error_substring) }
    puts "❌ FALHA: #{record.class} falhou por outros motivos, mas faltou o erro '#{error_substring}'."
    puts "   Erros reais: #{record.errors.full_messages}"
    exit(1)
  else
    puts "✅ PASSOU: Validação detectou corretamente '#{error_substring}'."
  end
end

def assert_valid(record)
  if record.valid?
    puts "✅ PASSOU: Registro válido com sucesso!"
  else
    puts "❌ FALHA: Registro deveria ser válido, mas falhou."
    puts "   Erros: #{record.errors.full_messages}"
    exit(1)
  end
end

suffix = SecureRandom.hex(4)
email = "test-#{suffix}@easysloting.com"
name = "Carlos Magno"

# ========================================================
# 🛡️ PARTE 1: TESTANDO MODELO USER (Colaboradores / Owners)
# ========================================================
puts "\n[TESTANDO MODELO USER]"

# 1.1 Senhas muito curtas (< 8 caracteres)
u = User.new(name: name, email: email, password: "Ab1!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "deve ter pelo menos 8 caracteres")

# 1.2 Senha sem letra maiúscula
u = User.new(name: name, email: email, password: "password123!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "deve conter pelo menos uma letra maiúscula")

# 1.3 Senha sem letra minúscula
u = User.new(name: name, email: email, password: "PASSWORD123!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "deve conter pelo menos uma letra minúscula")

# 1.4 Senha sem número
u = User.new(name: name, email: email, password: "Password!!!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "deve conter pelo menos um número")

# 1.5 Senha sem caractere especial
u = User.new(name: name, email: email, password: "Password1234", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "deve conter pelo menos um caractere especial")

# 1.6 Senha com termo óbvio ("easysloting")
u = User.new(name: name, email: email, password: "EasyslotPassword123!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "não pode conter termos óbvios")

# 1.7 Senha contendo partes do nome ("Carlos")
u = User.new(name: name, email: email, password: "CarlosSec1!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "não pode conter seu nome")

# 1.8 Senha contendo partes do e-mail ("test-#{suffix}")
u = User.new(name: name, email: email, password: "test-#{suffix}Sec1!", role: "employee", uid: email, provider: "email")
assert_invalid(u, :password, "não pode conter partes do seu e-mail")

# 1.9 Senha válida e forte
u = User.new(name: name, email: email, password: "SuperSecure2026Sml!", role: "employee", uid: email, provider: "email")
assert_valid(u)
u.save!

# 1.10 Prevenção de reuso da mesma senha
u.password = "SuperSecure2026Sml!"
assert_invalid(u, :password, "não pode ser igual à senha anterior")


# ========================================================
# 🛡️ PARTE 2: TESTANDO MODELO CUSTOMER (Clientes)
# ========================================================
puts "\n[TESTANDO MODELO CUSTOMER]"
est = Establishment.first || Establishment.create!(name: "Est Teste", slug: "est-#{suffix}")

# 2.1 Senhas muito curtas (< 8 caracteres)
c = Customer.new(name: name, email: email, password: "Ab1!", establishment: est)
assert_invalid(c, :password, "deve ter pelo menos 8 caracteres")

# 2.2 Senha sem letra maiúscula
c = Customer.new(name: name, email: email, password: "password123!", establishment: est)
assert_invalid(c, :password, "deve conter pelo menos uma letra maiúscula")

# 2.3 Senha sem letra minúscula
c = Customer.new(name: name, email: email, password: "PASSWORD123!", establishment: est)
assert_invalid(c, :password, "deve conter pelo menos uma letra minúscula")

# 2.4 Senha sem número
c = Customer.new(name: name, email: email, password: "Password!!!", establishment: est)
assert_invalid(c, :password, "deve conter pelo menos um número")

# 2.5 Senha sem caractere especial
c = Customer.new(name: name, email: email, password: "Password1234", establishment: est)
assert_invalid(c, :password, "deve conter pelo menos um caractere especial")

# 2.6 Senha com termo óbvio ("admin")
c = Customer.new(name: name, email: email, password: "AdminPassword123!", establishment: est)
assert_invalid(c, :password, "não pode conter termos óbvios")

# 2.7 Senha contendo partes do nome ("Carlos")
c = Customer.new(name: name, email: email, password: "CarlosSec1!", establishment: est)
assert_invalid(c, :password, "não pode conter seu nome")

# 2.8 Senha contendo partes do e-mail ("test-#{suffix}")
c = Customer.new(name: name, email: email, password: "test-#{suffix}Sec1!", establishment: est)
assert_invalid(c, :password, "não pode conter partes do seu e-mail")

# 2.9 Senha válida e forte
c = Customer.new(name: name, email: email, password: "SuperSecure2026Sml!", establishment: est)
assert_valid(c)
c.save!

# 2.10 Prevenção de reuso da mesma senha
c.password = "SuperSecure2026Sml!"
assert_invalid(c, :password, "não pode ser igual à senha anterior")


puts "\n========================================================"
puts "🎉 TODOS OS TESTES DE SEGURANÇA E COMPLEXIDADE PASSARAM!"
puts "========================================================\n"
