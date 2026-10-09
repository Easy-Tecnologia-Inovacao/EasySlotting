class Public::EstablishmentsController < ApplicationController
  def show
    establishment = Establishment.find_by!(slug: params[:slug], active: true)

    render json: {
      name: establishment.name,
      description: establishment.description,
      logo: establishment.logo,
      banner: establishment.banner,
      phone: establishment.phone,
      whatsapp: establishment.whatsapp,
      email: establishment.email,
      category: establishment.category,
      instagram: establishment.instagram,
      facebook: establishment.facebook,
      amenities: establishment.amenities || [],
      payment_methods: establishment.payment_methods || [],
      testimonials: establishment.testimonials || [],
      booking_mode: establishment.booking_mode,
      public_settings: establishment.public_settings || {},
      legal_pages: establishment.legal_pages || {},
      address: establishment.address ? {
        street: establishment.address.street,
        number: establishment.address.number,
        neighborhood: establishment.address.neighborhood,
        city: establishment.address.city,
        state: establishment.address.state,
        zip_code: establishment.address.zip_code,
        complement: establishment.address.complement,
        country: establishment.address.country
      } : nil,
      services: establishment.services.where(active: true).order(:name).map do |service|
        {
          id: service.id,
          name: service.name,
          description: service.description,
          price: service.price,
          duration_minutes: service.duration_minutes,
          active: service.active
        }
      end
    }
  end

  def legal_page
    establishment = Establishment.find_by!(slug: params[:slug], active: true)
    page_type = params[:page]

    valid_pages = %w[privacy_policy terms_of_use cookie_policy about_us faq contact_info]

    unless valid_pages.include?(page_type)
      return render json: { error: 'Página não encontrada.' }, status: :not_found
    end

    content = establishment.legal_pages&.dig(page_type) || ''

    if content.blank?
      return render json: { error: 'Esta página não foi configurada pelo estabelecimento.' }, status: :not_found
    end

    render json: {
      page_type: page_type,
      content: content,
      establishment_name: establishment.name
    }, status: :ok
  end
end