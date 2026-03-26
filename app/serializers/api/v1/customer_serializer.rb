module Api
  module V1
    class CustomerSerializer
      def self.render(record, company:)
        appointments = record.client_appointments.where(company_id: company.id)

        {
          id: record.id,
          first_name: record.first_name,
          last_name: record.last_name,
          full_name: record.full_name,
          email: record.email,
          phone: record.phone,
          appointments_count: appointments.count,
          last_appointment_at: appointments.maximum(:scheduled_at)&.iso8601,
          created_at: record.created_at&.iso8601,
          updated_at: record.updated_at&.iso8601
        }
      end
    end
  end
end
