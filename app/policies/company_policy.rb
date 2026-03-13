class CompanyPolicy < ApplicationPolicy
  def show?   = true  # Fiche publique accessible à tous
  def edit?   = owner?
  def update? = owner?

  def manage_employees? = owner? && company_active?
  def manage_settings?  = owner?
  def view_dashboard?   = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.company_admin?
        scope.where(user: user)
      else
        scope.active.with_public_booking
      end
    end
  end

  private

  def owner?
    user.present? && user.company_admin? && record.user == user
  end

  def company_active?
    record.active? || record.trial_active?
  end
end
