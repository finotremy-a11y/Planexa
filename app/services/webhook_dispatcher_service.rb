require "net/http"

class WebhookDispatcherService
  def self.dispatch!(company:, event:, payload:)
    new(company: company, event: event, payload: payload).dispatch!
  end

  def initialize(company:, event:, payload:)
    @company = company
    @event = event.to_s
    @payload_hash = payload
    @payload_json = payload.to_json
  end

  def dispatch!
    subscribed_webhooks.each do |webhook|
      post_webhook(webhook)
    rescue StandardError => e
      Rails.logger.error("Webhook dispatch failed (#{webhook.id}): #{e.class} #{e.message}")
    end
  end

  private

  attr_reader :company, :event, :payload_hash, :payload_json

  def subscribed_webhooks
    company.api_webhooks.active.select { |webhook| webhook.subscribed_to?(event) }
  end

  def post_webhook(webhook)
    uri = URI.parse(webhook.url)
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["X-Planexa-Event"] = event
    request["X-Planexa-Signature"] = webhook.signature_for(payload_json)
    request.body = payload_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 5, open_timeout: 5) do |http|
      response = http.request(request)
      Rails.logger.info("Webhook #{webhook.id} delivered: HTTP #{response.code}")
    end
  end
end
