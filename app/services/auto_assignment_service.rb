class AutoAssignmentService
  def initialize(company, service_type, scheduled_at, duration_minutes)
    @company          = company
    @service_type     = service_type
    @scheduled_at     = scheduled_at
    @duration_minutes = duration_minutes
  end

  # Retourne l'Employee assigné, ou nil si aucun disponible
  def call
    eligible_employees
      .sort_by { |emp| workload_score(emp) }
      .first
  end

  # Retourne true si au moins un employé est disponible (pour filtre "urgent")
  def any_available?
    eligible_employees.any?
  end

  private

  def eligible_employees
    # 1. Employés actifs de l'entreprise ayant la compétence requise
    candidates = @company.employees
                         .active
                         .skilled_for(@service_type)

    # 2. Filtrer ceux qui sont disponibles au créneau demandé
    candidates.select do |employee|
      AvailabilityChecker.new(employee, @scheduled_at, @duration_minutes).available?
    end
  end

  # Score de charge : nombre de RDV ce jour-là (moins = prioritaire)
  def workload_score(employee)
    employee.appointments
            .where(scheduled_at: @scheduled_at.beginning_of_day..@scheduled_at.end_of_day)
            .where.not(status: [:cancelled, :no_show])
            .count
  end
end
