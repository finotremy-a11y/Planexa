module Api
  module V1
    class EmployeeSerializer
      def self.render_collection(records)
        records.map { |record| render(record) }
      end

      def self.render(record)
        {
          id: record.id,
          first_name: record.first_name,
          last_name: record.last_name,
          full_name: record.full_name,
          email: record.email,
          phone: record.phone,
          active: record.active,
          service_type_ids: record.service_types.pluck(:id),
          created_at: record.created_at&.iso8601,
          updated_at: record.updated_at&.iso8601
        }
      end
    end
  end
end
