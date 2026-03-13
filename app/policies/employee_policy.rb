class EmployeePolicy < ApplicationPolicy
  def index?   = company_owner?
  def show?    = company_owner?
  def create?  = company_owner?
  def update?  = company_owner?
  def destroy? = company_owner?
  def toggle_active? = company_owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.company_admin?
        scope.where(company: user.company)
      else
        scope.none
      end
    end
  end

  private

  def company_owner?
    user.present? && user.company_admin? && record.company == user.company
  end
end
