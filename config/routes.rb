Rails.application.routes.draw do
  # ── Auth (Devise) ────────────────────────────────────────────────────────
  devise_for :users
  # controllers: {
  # registrations: "users/registrations",
  # sessions:      "users/sessions",
  # confirmations: "users/confirmations"
  # }

  # ── Page d'accueil & Recherche publique ──────────────────────────────────
  root "home#index"

  # Changement de langue (persisté en session et profil utilisateur)
  patch "/locale/:locale", to: "locales#update", as: :locale

  # Recherche d'entreprises (côté client non connecté ou connecté)
  get  "/recherche",          to: "search#index",  as: :search
  get  "/recherche/:activity_slug/:city_slug", to: "search#landing", as: :seo_search_landing
  get  "/entreprises/:id",    to: "companies#show", as: :company_public

  # Pages légales & contact
  get  "/cgu", to: "pages#cgu", as: :cgu
  get  "/cgv", to: "pages#cgv", as: :cgv
  get  "/confidentialite", to: "pages#confidentialite", as: :confidentialite
  get  "/mentions-legales", to: "pages#mentions_legales", as: :mentions_legales
  get  "/contact", to: "pages#contact", as: :contact
  get  "/tarifs",  to: "pages#tarifs",  as: :tarifs
  post "/contact", to: "pages#send_contact", as: :send_contact

  # Prise de RDV publique
  resources :appointments, only: [ :new, :create, :show ], path: "rendez-vous" do
    member do
      get :reconfirm
    end
    collection do
      get :confirmation
    end
  end

  # Réservation multi-prestation
  resources :bookings, only: [ :new, :create ], path: "reservations" do
    collection do
      get :confirmation
    end
  end

  # Widget de réservation embarquable (iFrame / script)
  scope "/widget", as: :widget do
    get  "/:company_token",              to: "widget#booking",      as: :booking
    post "/:company_token/reservation",  to: "widget#create",       as: :booking_create
    get  "/:company_token/confirmation", to: "widget#confirmation", as: :booking_confirmation
  end

  # Avis clients (via token e-mail)
  get  "avis/merci",  to: "reviews#submitted",  as: :submitted_reviews
  get  "avis/:token", to: "reviews#show",        as: :review
  post "avis/:token", to: "reviews#submit",       as: :submit_review

  # Liste d'attente (public)
  get  "liste-attente/nouveau",          to: "waitlist_entries#new",       as: :new_waitlist_entry
  post "liste-attente",                  to: "waitlist_entries#create",    as: :waitlist_entries
  get  "liste-attente/merci",            to: "waitlist_entries#submitted", as: :waitlist_submitted
  get  "liste-attente/confirmer/:token", to: "waitlist_entries#confirm",   as: :waitlist_confirm

  # ── Paiement client après RDV ────────────────────────────────────────────
  scope path: "rendez-vous/:appointment_id", as: "appointment" do
    resource :payment, only: [ :new, :create ], path: "paiement", controller: "payments"
  end

  # ── Stripe webhooks (AVANT les namespaces pour éviter CSRF) ──────────────
  post "/stripe/webhooks", to: "stripe/webhooks#create"

  # ── Espace Client ────────────────────────────────────────────────────────
  namespace :client do
    root "dashboard#index"
    resources :conversations, only: [ :index, :show ], path: "messagerie" do
      resources :messages, only: [ :create ], controller: "conversation_messages"
    end
    resources :appointments, only: [ :index, :show, :destroy ], path: "mes-rdv" do
      member do
        patch :cancel
      end
    end
    resources :payments, only: [ :show ]
    resources :invoices, only: [ :index, :show ], path: "factures" do
      member do
        get :download, path: "telecharger"
      end
    end
    resource  :profile, only: [ :show, :edit, :update ]
    resources :loyalty, only: [ :index, :show ], path: "fidelite"
  end

  # ── Espace Entreprise ─────────────────────────────────────────────────────
  namespace :company do
    root "dashboard#index"

    resources :conversations, only: [ :index, :show ], path: "messagerie" do
      resources :messages, only: [ :create ], controller: "conversation_messages"
    end

    # Onboarding (étapes initiales après inscription)
    resource :onboarding, only: [ :show, :update ], path: "onboarding"

    # Réglages
    resource :settings, only: [ :show, :update ], path: "reglages"
    resources :company_closures, only: [ :index, :new, :create, :destroy ], path: "fermetures-cabinet"
    resource :loyalty_settings, only: [ :show, :update ], path: "fidelite"
    resources :api_tokens, only: [ :index, :create, :destroy ], path: "api-tokens"

    # Widget embarquable
    resource :widget_settings, only: [ :show ], path: "widget" do
      post :regenerate_token, path: "regenerer-token", on: :member
    end

    # Notifications temps réel
    resources :notifications, only: [ :index ], path: "notifications" do
      member do
        patch :mark_read, path: "marquer-lu"
      end
      collection do
        patch :mark_all_read, path: "tout-marquer-lu"
      end
    end

    # Abonnement & Facturation
    resource :subscription, only: [ :show, :new, :create, :destroy ], path: "abonnement" do
      post :checkout          # → Stripe Checkout
      post :portal            # → Stripe Billing Portal
    end

    # Stripe Connect (pour recevoir paiements clients)
    resource :stripe_connect, only: [], path: "stripe-connect" do
      get  :connect           # Lance l'onboarding Stripe Express
      get  :return            # Retour après onboarding
      get  :refresh           # Renouvellement du lien
    end

    # Employés
    resources :employees, path: "employes" do
      member do
        patch :toggle_active
      end
      resources :skills, only: [ :index, :create, :destroy ],
                         controller: "employee_skills", path: "aptitudes"
      resources :schedules, only: [ :index, :create, :destroy ],
                            path: "horaires"
      resources :employee_absences, only: [ :index, :new, :create, :edit, :update, :destroy ],
                                    path: "absences"
    end

    # Prestations / Domaines d'activité
    resources :service_types, path: "prestations", except: [ :show ] do
      collection do
        post :quick_create
      end
      member do
        patch :toggle_active
      end
    end

    # Rendez-vous
    resources :appointments, path: "rendez-vous" do
      member do
        patch :confirm
        patch :cancel
        patch :complete
        patch :assign_employee    # Assignation manuelle
      end
      collection do
        get :calendar             # Vue calendrier
        get :unassigned           # RDV sans employé assigné
      end
    end

    # Planning
    resources :schedules, only: [ :index ], path: "planning"

    # Profil entreprise
    resource :profile, only: [ :show, :edit, :update ], path: "profil"

    # Avis reçus
    resources :reviews, only: [ :index, :show, :destroy ], path: "avis"

    # Groupes de réservation multi-prestation
    resources :booking_groups, only: [ :index, :show ], path: "groupes-rdv"

    # Liste d'attente
    resources :waitlist_entries, only: [ :index, :show, :destroy ], path: "liste-attente"

    # Clients inactifs (relance)
    resources :inactive_clients, only: [ :index ], path: "clients-inactifs"

    # Factures & export comptable
    resources :invoices, only: [ :index, :show ], path: "factures" do
      member do
        get :download, path: "telecharger"
      end
      collection do
        get :export_csv, path: "export-csv"
      end
    end

    # Statistiques & analytiques
    get "statistiques",        to: "statistics#index",      as: :statistics
    get "statistiques/export", to: "statistics#export_csv", as: :export_statistics_csv
  end

  # Backward-compatible alias for old helper calls.
  get "/company/onboarding/new", to: redirect("/company/onboarding"), as: :new_company_onboarding

  # ── Espace Admin ──────────────────────────────────────────────────────────
  namespace :admin do
    root "dashboard#index"

    resources :companies, only: [ :index, :show, :destroy ] do
      member do
        patch :suspend
        patch :reactivate
      end
    end

    resources :users, only: [ :index, :show, :destroy ]

    resources :subscriptions, only: [ :index, :show ] do
      member do
        patch :cancel
      end
    end

    resources :reviews, only: [ :index, :show, :destroy ] do
      member do
        patch :publish
        patch :unpublish
      end
    end

    get  "/metrics",   to: "dashboard#metrics",   as: :metrics
    get  "/export",    to: "dashboard#export_csv", as: :export_csv
  end

  # ── Sidekiq Web UI (admin seulement) ─────────────────────────────────────
  require "sidekiq/web"
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  # ── API Publique (PWA & Intégrations) ────────────────────────────────────
  namespace :api do
    namespace :v1 do
      # Push Notifications (PWA)
      resources :push_subscriptions, only: [ :create, :destroy ] do
        collection do
          get :vapid_key
        end
      end

      resources :appointments, only: [ :index, :show, :create, :update, :destroy ]
      resources :employees, only: [ :index ]
      resources :service_types, only: [ :index ]
      resources :customers, only: [ :index, :show ]
      resources :webhooks, only: [ :index, :create, :destroy ]
      get "availability", to: "availability#index"
    end
  end

  # ── Health check (Render) ─────────────────────────────────────────────────
  get "/up", to: "rails/health#show", as: :rails_health_check

  # ── Pages d'erreur custom ─────────────────────────────────────────────────
  match "/404", to: "errors#not_found",             via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
