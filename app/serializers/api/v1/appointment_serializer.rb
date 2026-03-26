module Api
  module V1
    class AppointmentSerializer
      def self.render_collection(records)
        records.map { |record| render(record) }
      end

      def self.render(record)
        {
          id: record.id,
          status: record.status,
          scheduled_at: record.scheduled_at&.iso8601,
          duration_minutes: record.duration_minutes,
          urgent: record.urgent,
          client_notes: record.client_notes,
          internal_notes: record.internal_notes,
          cancellation_reason: record.cancellation_reason,
          service_type: service_type_data(record),
          employee: employee_data(record),
          customer: customer_data(record),
          created_at: record.created_at&.iso8601,
          updated_at: record.updated_at&.iso8601
        }
      end

      def self.service_type_data(record)
        return nil unless record.service_type

        {
          id: record.service_type.id,
          name: record.service_type.name,
          duration_minutes: record.service_type.duration_minutes,
          price_cents: record.service_type.price_cents,
          currency: record.service_type.price_currency
        }
      end

      def self.employee_data(record)
        return nil unless record.employee

        {
          id: record.employee.id,
          full_name: record.employee.full_name,
          email: record.employee.email
        }
      end

      def self.customer_data(record)
        return nil unless record.client_user

        {
          id: record.client_user.id,
          first_name: record.client_user.first_name,
          last_name: record.client_user.last_name,
          email: record.client_user.email,
          phone: record.client_user.phone
        }
      end
    end
  end
end
