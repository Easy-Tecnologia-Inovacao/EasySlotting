# Corrige end_times via SQL puro, sem passar por conversão do Ruby/Rails
puts "Corrigindo end_times via SQL direto..."

fixed = 0
Appointment.find_each do |a|
  service = a.service
  next unless service

  duration = service.duration_minutes.to_i
  next if duration <= 0

  # Lê start_time e end_time diretamente do banco como texto
  raw = ActiveRecord::Base.connection.execute(
    "SELECT start_time::text, end_time::text FROM appointments WHERE id = #{a.id}"
  ).first

  start_str = raw['start_time'][0, 5]  # "HH:MM"
  actual_end_str = raw['end_time'][0, 5]  # "HH:MM"

  # Calcula end_time correto a partir do start_time puro (sem timezone)
  sh, sm = start_str.split(':').map(&:to_i)
  start_minutes = sh * 60 + sm
  end_minutes   = start_minutes + duration
  eh = end_minutes / 60
  em = end_minutes % 60
  expected_end_str = format('%02d:%02d', eh, em)

  if actual_end_str != expected_end_str
    puts "  Corrigindo ID #{a.id}: #{start_str}->#{actual_end_str} → #{start_str}->#{expected_end_str}"
    # Usa SQL puro para salvar sem conversão de timezone
    ActiveRecord::Base.connection.execute(
      "UPDATE appointments SET end_time = '#{expected_end_str}:00' WHERE id = #{a.id}"
    )
    fixed += 1
  end
end

puts "Concluido. #{fixed} agendamentos corrigidos."

# Verificacao final
puts "\nVerificacao final (IDs recentes):"
result = ActiveRecord::Base.connection.execute(
  "SELECT id, start_time::text, end_time::text, duration_minutes FROM appointments WHERE id >= 21 ORDER BY id"
)
result.each do |row|
  sh, sm = row['start_time'].split(':').map(&:to_i)
  eh, em = row['end_time'].split(':').map(&:to_i)
  diff = (eh * 60 + em) - (sh * 60 + sm)
  puts "  ID #{row['id']}: #{row['start_time'][0,5]}->#{row['end_time'][0,5]} diff=#{diff}min (dur=#{row['duration_minutes']})"
end
