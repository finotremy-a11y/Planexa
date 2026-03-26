# Configuration CORS pour les endpoints du widget embarquable.
# Permet aux sites tiers d'effectuer des requêtes fetch/XHR vers le widget.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "/widget/*",
      headers: :any,
      methods: [ :get, :post, :options ],
      expose:  [ "X-CSRF-Token" ]
  end
end
