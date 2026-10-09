Rails.application.routes.draw do
  get '/up', to: 'rails/health#show', as: :rails_health_check

  scope path: '/api' do
    mount ActionCable.server => '/cable'

    mount_devise_token_auth_for 'User',
      at: 'devise_users',
      controllers: {
        sessions: 'devise_users/sessions',
        registrations: 'devise_users/registrations',
        passwords: 'devise_users/passwords',
        confirmations: 'devise_users/confirmations'
      }

    devise_scope :user do
      post '/register', to: 'devise_users/registrations#create'
    end

    post '/owner_onboarding', to: 'account/onboarding#create'

    # =========================
    # AUTH DE CUSTOMERS (por estabelecimento)
    # Cada estabelecimento tem seu próprio endpoint de cadastro/login de cliente.
    # A unicidade do email é por [email + slug/establishment_id].
    # =========================
    namespace :customer_auth do
      scope ':slug' do
        post '/sign_up',  to: 'registrations#create'
        post '/sign_in',  to: 'sessions#create'
        post '/refresh',  to: 'sessions#refresh'
        delete '/sign_out', to: 'sessions#destroy'
        post '/forgot_password', to: 'passwords#create'
        put  '/reset_password',  to: 'passwords#update'
      end
    end

    # =========================
    # ADMIN (Mapeados para a pasta admin/)
    # =========================
    namespace :admin do
      resource :establishment, only: [:show, :update] do
        post :upload_logo
        post :upload_banner
      end

      resources :team, only: [:index, :create, :update, :destroy] do
        collection do
          patch :bulk_schedule, to: 'team_schedule#bulk_update'
          get :all_schedules, to: 'team_schedule#all_schedules'
        end
        member do
          get :schedule, to: 'team_schedule#show'
          patch :schedule, to: 'team_schedule#update'
        end
      end

      resources :customers, only: [:index]
      resources :feedbacks, only: [:index]
      resources :notifications, only: [:index] do
        collection do
          patch :read_all
        end
        member do
          patch :read
        end
      end
    end

    # Estes não usam o caminho /admin/ na URL, mas os controllers estão na pasta admin/
    scope module: :admin do
      resources :services, only: [:index, :create, :update, :destroy]
      resources :service_packages, only: [:index, :create, :update, :destroy]
      resources :stock_items, only: [:index, :create, :update, :destroy] do
        member do
          post :add_stock
        end
      end

      resources :appointments, only: [:index, :create] do
        collection do
          get :available_slots
        end
        member do
          patch :complete
          patch :cancel
          patch :reschedule
          get :package_occupied_weeks
        end
      end
    end

    # =========================
    # CLIENTE (LOGADO) - (Mapeados para a pasta customer/)
    # =========================
    namespace :customer do
      resource :profile, controller: 'profile', only: [:show, :update, :destroy] do
        post :upload_image
        post :change_password
        get :sessions
        get :export
        patch :revoke_consent
      end

      resources :notifications, only: [:index] do
        member do
          patch :read
        end
        collection do
          patch :read_all
        end
      end
      
      resources :appointments, only: [:index, :create] do
        collection do
          get :history
        end
        member do
          patch :cancel
          patch :reschedule
          patch :confirm
        end
        # Feedback anônimo — um por agendamento
        resource :feedback,
                 only:       [:create],
                 controller: 'appointment_feedbacks'
      end

      resources :service_packages, only: [:index] do
        collection do
          get :available
        end
        member do
          patch :cancel
        end
      end
    end

    # =========================
    # MINHA CONTA - (Mapeados para a pasta account/ sem namespace na URL)
    # =========================
    patch '/me/change_password', to: 'account/users#change_password'
    get   '/me/export',          to: 'account/users#export'
    delete '/me/account',        to: 'account/users#destroy'
    patch '/me/revoke_consent',  to: 'account/users#revoke_consent'
    get   '/me/sessions',        to: 'account/users#sessions'
    delete '/me/sessions/:client_id', to: 'account/users#destroy_session'
    delete '/me/sessions',       to: 'account/users#destroy_other_sessions'
    get   '/me/subscription',    to: 'account/subscriptions#show_current'

    patch '/subscriptions/:id/cancel', to: 'account/subscriptions#cancel'
    post  '/subscriptions',            to: 'account/subscriptions#create'

    # =========================
    # PÚBLICO (SITE) - (Mapeados para a pasta public/)
    # =========================
    namespace :public do
      resources :establishments, param: :slug, only: [:show] do
        member do
          get :booking_data,       to: 'booking#booking_data'
          get :available_days,     to: 'booking#available_days'
          get :available_slots,    to: 'booking#available_slots'
          get :service_packages,   to: 'booking#service_packages'
          get :legal_page,         to: 'establishments#legal_page'
        end
      end
    end

    # =========================
    # PLANOS
    # =========================
    resources :plans, only: [:index], controller: 'public/plans'

    # =========================
    # FINANCEIRO
    # =========================
    namespace :financial do
      get '/dashboard', to: 'dashboard#index'
      resources :reports, only: [:index]
      resources :packages, only: [:index]
      resources :services, only: [:index]

      resources :commissions, only: [:index]

      resources :commission_closings, only: [:index, :show, :create] do
        collection do
          get :preview
          get :report
        end
        member do
          post :reopen
        end
      end
    end

    # =========================
    # SUPER ADMIN
    # =========================
    namespace :super_admin do
      get '/dashboard', to: 'dashboard#index'
      resources :plans, only: [:index, :create, :update]

      # Audit Logs - Visualização de logs de segurança
      resources :audit_logs, only: [:index] do
        collection do
          get :security_summary
        end
      end
    end
  end
end
