Rails.application.routes.draw do

  # ── Auth (Devise) ────────────────────────────────────────────────────────
  devise_for :users
#controllers: {
#registrations: "users/registrations",
#sessions:      "users/sessions",
#confirmations: "users/confirmations"
#}

  # ── Page d'accueil & Recherche publique ──────────────────────────────────
  root "home#index"

  # Recherche d'entreprises (côté client non connecté ou connecté)
  get  "/recherche",          to: "search#index",  as: :search
  get  "/entreprises/:id",    to: "companies#show", as: :company_public

  # Prise de RDV publique
  resources :appointments, only: [:new, :create, :show], path: "rendez-vous" do
    collection do
      get :confirmation
    end
  end

  # ── Stripe webhooks (AVANT les namespaces pour éviter CSRF) ──────────────
  post "/stripe/webhooks", to: "stripe/webhooks#create"

  # ── Espace Client ────────────────────────────────────────────────────────
  namespace :client do
    root "dashboard#index"
    resources :appointments, only: [:index, :show, :destroy], path: "mes-rdv" do
      member do
        patch :cancel
      end
    end
    resources :payments, only: [:show]
    resource  :profile, only: [:show, :edit, :update]
  end

  # ── Espace Entreprise ─────────────────────────────────────────────────────
  namespace :company do
    root "dashboard#index"

    # Onboarding (étapes initiales après inscription)
    resource :onboarding, only: [:show, :update], path: "onboarding"

    # Réglages
    resource :settings, only: [:show, :update], path: "reglages"

    # Abonnement & Facturation
    resource :subscription, only: [:show, :new, :create, :destroy], path: "abonnement" do
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
      resources :skills, only: [:index, :create, :destroy],
                         controller: "employee_skills", path: "aptitudes"
      resources :schedules, only: [:index, :new, :create, :destroy],
                            path: "horaires"
    end

    # Prestations / Domaines d'activité
    resources :service_types, path: "prestations" do
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
    resources :schedules, only: [:index], path: "planning"

    # Profil entreprise
    resource :profile, only: [:show, :edit, :update], path: "profil"
  end

  # ── Espace Admin ──────────────────────────────────────────────────────────
  namespace :admin do
    root "dashboard#index"

    resources :companies, only: [:index, :show, :destroy] do
      member do
        patch :suspend
        patch :reactivate
      end
    end

    resources :users, only: [:index, :show, :destroy]

    resources :subscriptions, only: [:index, :show] do
      member do
        patch :cancel
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

  # ── Health check (Render) ─────────────────────────────────────────────────
  get "/up", to: "rails/health#show", as: :rails_health_check
end
