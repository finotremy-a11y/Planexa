module Api
  module V1
    class WebhookSerializer
      def self.render_collection(records)
        records.map { |record| render(record) }
      end

      def self.render(record)
        {
          id: record.id,
          url: record.url,
          events: record.events,
          active: record.active,
          secret_preview: secret_preview(record.secret),
          created_at: record.created_at&.iso8601,
          updated_at: record.updated_at&.iso8601
        }
      end

      def self.secret_preview(secret)
        return nil if secret.blank?

        "#{secret.first(6)}...#{secret.last(4)}"
      end
    end
  end
end
