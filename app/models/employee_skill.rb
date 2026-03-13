class EmployeeSkill < ApplicationRecord
  belongs_to :employee
  belongs_to :service_type

  enum :level, { beginner: 1, intermediate: 2, expert: 3 }

  validates :employee_id, uniqueness: { scope: :service_type_id,
    message: "possède déjà cette aptitude" }
end
