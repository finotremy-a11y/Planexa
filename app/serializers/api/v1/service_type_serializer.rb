module Api
  module V1
    class ServiceTypeSerializer
      def self.render_collection(records)
        records.map { |record| render(record) }
      end

      def self.render(record)
        {
          id: record.id,
          name: record.name,
          description: record.description,
          duration_minutes: record.duration_minutes,
          price_cents: record.price_cents,
          currency: record.price_currency,
          active: record.active,
          created_at: record.created_at&.iso8601,
          updated_at: record.updated_at&.iso8601
        }
      end
    end
  end
end
