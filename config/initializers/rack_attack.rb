# frozen_string_literal: true

class Rack::Attack
  # ── Throttles IP globale (protection DDoS basique) ────────────────────────
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # ── Login : 5 tentatives par IP toutes les 15 minutes ─────────────────────
  throttle("logins/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # ── Login : 10 tentatives par email toutes les 30 minutes ─────────────────
  throttle("logins/email", limit: 10, period: 30.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email").to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # ── Mot de passe oublié : 3 tentatives par email toutes les heures ────────
  throttle("password_reset/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.params.dig("user", "email").to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # ── Inscription : 5 tentatives par IP toutes les 10 minutes ──────────────
  throttle("signup/ip", limit: 5, period: 10.minutes) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # ── Webhooks Stripe : protégés séparément ────────────────────────────────
  # Les webhooks Stripe ont leur propre validation par signature,
  # on limite à 60 appels/minute par IP pour prévenir le flood.
  throttle("stripe_webhooks/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path == "/stripe/webhooks"
  end

  # ── Réponse pour les requêtes bloquées ────────────────────────────────────
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now        = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit"     => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset"     => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Content-Type"        => "application/json"
    }

    [ 429, headers, [ { error: "Trop de tentatives. Veuillez réessayer plus tard." }.to_json ] ]
  end

  # ── Logging des requêtes bloquées ─────────────────────────────────────────
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.env['rack.attack.matched']} — IP: #{req.ip} — Path: #{req.path}"
  end
end
