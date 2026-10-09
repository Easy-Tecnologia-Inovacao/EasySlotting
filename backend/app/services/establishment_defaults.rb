# frozen_string_literal: true

# Service que centraliza os modelos padrão LGPD para páginas legais.
# Usado tanto no onboarding (criação) quanto nos seeds.
# Os marcadores [ NOME DO SEU ESTABELECIMENTO ] ficam para o dono substituir no editor.
module EstablishmentDefaults
  def self.legal_pages(establishment_name = nil)
    name_marker = establishment_name.presence || '[ NOME DO SEU ESTABELECIMENTO ]'

    {
      'privacy_policy' => <<~HTML.strip,
        <h2>1. Controlador dos Dados</h2>
        <p>O controlador dos dados pessoais é o estabelecimento parceiro <strong>#{name_marker}</strong> onde você realizou seu cadastro. A EasySloting atua como operadora de dados, processando informações em nome do estabelecimento.</p>

        <h2>2. Dados Coletados</h2>
        <p>Coletamos as seguintes informações durante o uso dos nossos serviços:</p>
        <ul>
          <li><strong>Dados de cadastro:</strong> Nome, e-mail, telefone e celular</li>
          <li><strong>Dados de agendamento:</strong> Data, horário, serviço selecionado e profissional</li>
          <li><strong>Dados de navegação:</strong> Informações de acesso (IP, dispositivo, navegador) para fins de segurança</li>
          <li><strong>Feedbacks:</strong> Avaliações e comentários (sempre anônimos)</li>
        </ul>

        <h2>3. Finalidade do Tratamento</h2>
        <p>Seus dados são utilizados para:</p>
        <ul>
          <li>Processar e confirmar agendamentos no <strong>#{name_marker}</strong></li>
          <li>Enviar notificações sobre seus atendimentos</li>
          <li>Gerenciar pacotes mensais e assinaturas</li>
          <li>Garantir a segurança da sua conta</li>
          <li>Melhorar a qualidade dos serviços</li>
          <li>Cumprir obrigações legais e fiscais</li>
        </ul>

        <h2>4. Base Legal</h2>
        <p>O tratamento dos seus dados é realizado com base em:</p>
        <ul>
          <li><strong>Execução de contrato:</strong> Prestação dos serviços de agendamento</li>
          <li><strong>Consentimento:</strong> Para comunicações de marketing (quando aplicável)</li>
          <li><strong>Legítimo interesse:</strong> Para segurança e melhoria dos serviços</li>
        </ul>

        <h2>5. Compartilhamento de Dados</h2>
        <p>Não compartilhamos seus dados pessoais com terceiros para fins de marketing. Seus dados podem ser compartilhados apenas quando:</p>
        <ul>
          <li>Necessário para cumprir obrigação legal ou regulatória</li>
          <li>Autorizado por você de forma expressa</li>
          <li>Necessário para a prestação do serviço contratado</li>
          <li>Proteção dos direitos do estabelecimento ou da EasySloting</li>
        </ul>

        <h2>6. Segurança dos Dados</h2>
        <p>Implementamos medidas de segurança técnicas e organizacionais robustas:</p>
        <ul>
          <li>Criptografia de dados em trânsito (HTTPS/TLS)</li>
          <li>Senhas armazenadas com hash bcrypt (irrecuperáveis)</li>
          <li>Controle de acesso por autenticação JWT</li>
          <li>Registro de auditoria de todas as ações sensíveis</li>
          <li>Rate limiting para prevenir abusos</li>
        </ul>

        <h2>7. Retenção dos Dados</h2>
        <p>Seus dados são mantidos pelo tempo necessário para cumprir as finalidades descritas nesta política, salvo quando houver obrigação legal de retenção superior.</p>

        <h2>8. Seus Direitos (LGPD)</h2>
        <p>Conforme a Lei Geral de Proteção de Dados, você tem direito a:</p>
        <ul>
          <li><strong>Confirmação:</strong> Saber se tratamos seus dados</li>
          <li><strong>Acesso:</strong> Obter cópia dos seus dados</li>
          <li><strong>Correção:</strong> Corrigir dados incompletos ou desatualizados</li>
          <li><strong>Anonimização/Bloqueio/Exclusão:</strong> De dados desnecessários ou excessivos</li>
          <li><strong>Portabilidade:</strong> Solicitar transferência dos seus dados</li>
          <li><strong>Eliminação:</strong> Solicitar a exclusão dos dados tratados com consentimento</li>
          <li><strong>Revogação:</strong> Revogar o consentimento a qualquer momento</li>
          <li><strong>Oposição:</strong> Opor-se ao tratamento em certas hipóteses</li>
        </ul>

        <h2>9. Cookies</h2>
        <p>Utilizamos cookies essenciais para o funcionamento do site. Para mais detalhes, consulte nossa Política de Cookies.</p>

        <h2>10. Transferência Internacional</h2>
        <p>Seus dados não são transferidos para fora do Brasil, salvo quando estritamente necessário e com as garantias legais exigidas pela LGPD.</p>

        <h2>11. Menores de Idade</h2>
        <p>Nossos serviços são destinados a maiores de 18 anos. Em caso de necessidade de tratamento de dados de menores, o consentimento deverá ser dado pelo responsável legal.</p>

        <h2>12. Alterações nesta Política</h2>
        <p>Esta Política de Privacidade pode ser atualizada periodicamente. Recomendamos que você consulte esta página regularmente.</p>

        <h2>13. Canal de Comunicação</h2>
        <p>Para exercer seus direitos ou esclarecer dúvidas sobre esta política, entre em contato diretamente com o <strong>#{name_marker}</strong> pelo e-mail <strong>[ EMAIL DO ESTABELECIMENTO ]</strong> ou telefone <strong>[ TELEFONE / CONTATO ]</strong>.</p>

        <p><em>Última atualização: [ DATA DE ATUALIZAÇÃO ]</em></p>
        <p><em>Política gerenciada pela plataforma EasySloting em conformidade com a LGPD.</em></p>
      HTML

      'terms_of_use' => <<~HTML.strip,
        <h2>1. Definições</h2>
        <ul>
          <li><strong>Plataforma:</strong> Sistema EasySloting de agendamento online</li>
          <li><strong>Estabelecimento:</strong> <strong>#{name_marker}</strong></li>
          <li><strong>Cliente:</strong> Usuário que realiza cadastro e agendamentos</li>
          <li><strong>Serviço:</strong> Atendimento oferecido pelo <strong>#{name_marker}</strong></li>
        </ul>

        <h2>2. Cadastro</h2>
        <ul>
          <li>Para utilizar a plataforma, é necessário criar uma conta com informações verdadeiras e atualizadas</li>
          <li>O cliente é responsável por manter a confidencialidade de sua senha</li>
          <li>É proibido o cadastro com dados falsos ou de terceiros</li>
          <li>O <strong>#{name_marker}</strong> pode recusar ou cancelar cadastros que violem estes termos</li>
        </ul>

        <h2>3. Agendamentos</h2>
        <ul>
          <li>Agendamentos estão sujeitos à disponibilidade de horários e profissionais</li>
          <li>A confirmação do agendamento é enviada por e-mail após a conclusão</li>
          <li>O cliente deve chegar no horário agendado. Atrasos superiores a 15 minutos podem resultar no cancelamento</li>
          <li>Em caso de não comparecimento (no-show), o <strong>#{name_marker}</strong> poderá aplicar restrições futuras</li>
        </ul>

        <h2>4. Cancelamentos e Reagendamentos</h2>
        <ul>
          <li>O cliente pode cancelar ou reagendar pela plataforma</li>
          <li>Cancelamentos devem ser feitos com antecedência mínima de 2 horas</li>
        </ul>

        <h2>5. Pagamentos</h2>
        <ul>
          <li>Os preços são definidos pelo <strong>#{name_marker}</strong> e podem ser alterados sem aviso prévio</li>
          <li>O pagamento é realizado diretamente no estabelecimento na data do atendimento</li>
        </ul>

        <h2>6. Legislação Aplicável</h2>
        <p>Estes termos são regidos pelas leis do Brasil. Fica eleito o foro da comarca de <strong>[ CIDADE / UF ]</strong> para dirimir quaisquer questões.</p>

        <p><em>Última atualização: [ DATA DE ATUALIZAÇÃO ]</em></p>
      HTML

      'cookie_policy' => <<~HTML.strip,
        <h2>1. O que são Cookies?</h2>
        <p>Cookies são pequenos arquivos de texto armazenados no seu dispositivo ao navegar no site do <strong>#{name_marker}</strong>.</p>

        <h2>2. Cookies que Utilizamos</h2>
        <ul>
          <li><strong>Cookies Essenciais:</strong> Necessários para login, navegação e segurança da sua conta</li>
          <li><strong>Cookies de Preferências:</strong> Armazenam suas escolhas (ex: tema claro ou escuro)</li>
        </ul>

        <h2>3. Como Gerenciar Cookies</h2>
        <p>Você pode desativar os cookies no seu navegador a qualquer momento.</p>

        <p><em>Última atualização: [ DATA DE ATUALIZAÇÃO ]</em></p>
      HTML

      'about_us' => <<~HTML.strip,
        <h2>Sobre o #{name_marker}</h2>
        <p>Bem-vindo ao <strong>#{name_marker}</strong>! Somos dedicados a oferecer os melhores serviços com excelência e conforto.</p>

        <h2>Nossa Missão</h2>
        <p>Proporcionar um atendimento de altíssima qualidade com agilidade no agendamento e transparência.</p>

        <h2>Entre em Contato</h2>
        <p>Fale conosco pelo e-mail <strong>[ EMAIL DO ESTABELECIMENTO ]</strong> ou telefone <strong>[ TELEFONE / CONTATO ]</strong>.</p>
      HTML

      'faq' => <<~HTML.strip,
        <h2>Perguntas Frequentes - #{name_marker}</h2>

        <h2>1. Como realizo um agendamento?</h2>
        <p>Basta escolher o serviço, o profissional desejado, selecionar o melhor dia e horário disponível e confirmar o agendamento.</p>

        <h2>2. Posso cancelar meu agendamento?</h2>
        <p>Sim! Você pode cancelar ou reagendar diretamente pelo painel do cliente com até 2 horas de antecedência.</p>

        <h2>3. Quais são as formas de pagamento?</h2>
        <p>O pagamento é feito diretamente no <strong>#{name_marker}</strong> no momento do atendimento.</p>
      HTML

      'contact_info' => <<~HTML.strip
        <h2>Canais de Atendimento - #{name_marker}</h2>
        <ul>
          <li><strong>Empresa:</strong> #{name_marker}</li>
          <li><strong>E-mail:</strong> [ EMAIL DO ESTABELECIMENTO ]</li>
          <li><strong>Telefone / WhatsApp:</strong> [ TELEFONE / CONTATO ]</li>
          <li><strong>Localização:</strong> [ CIDADE / UF ]</li>
        </ul>
      HTML
    }
  end
end
