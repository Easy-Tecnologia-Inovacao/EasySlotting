class AddLegalPagesToEstablishments < ActiveRecord::Migration[8.0]
  def change
    add_column :establishments, :legal_pages, :jsonb, default: {}

    # Estrutura do legal_pages:
    # {
    #   "privacy_policy": "Conteúdo da Política de Privacidade...",
    #   "terms_of_use": "Conteúdo dos Termos de Uso...",
    #   "cookie_policy": "Conteúdo da Política de Cookies...",
    #   "about_us": "Conteúdo Quem Somos...",
    #   "faq": "Conteúdo FAQ...",
    #   "contact_info": "Informações de contato..."
    # }
  end
end
