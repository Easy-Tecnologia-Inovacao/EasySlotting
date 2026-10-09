# Script para corrigir end_times erradas nos agendamentos corrompidos
# Os IDs 21-26 têm end_time = start + 140min em vez de start + duration_minutes

puts "Corrigindo end_times erradas..."

fixed = 0
Appointment.find_each do |a|
  service = a.service
  next unless service

  duration = service.duration_minutes.to_i
  next if duration <= 0

  # Normaliza start_time para string HH:MM
  start_str = if a.start_time.respond_to?(:strftime)
    a.start_time.in_time_zone(Time.zone).strftime('%H:%M')
  else
    a.start_time.to_s[0, 5]
  end

  # Calcula end_time correto
  expected_end_str = (Time.zone.parse("2000-01-01 #{start_str}") + duration.minutes).strftime('%H:%M')

  # Lê end_time atual como string local
  actual_end_str = if a.end_time.respond_to?(:strftime)
    a.end_time.in_time_zone(Time.zone).strftime('%H:%M')
  else
    a.end_time.to_s[0, 5]
  end

  if actual_end_str != expected_end_str
    puts "  Corrigindo ID #{a.id}: #{start_str}->#{actual_end_str} (dur=#{duration}) → #{start_str}->#{expected_end_str}"
    a.update_columns(end_time: expected_end_str)
    fixed += 1
  end
end

puts "Concluido. #{fixed} agendamentos corrigidos."
