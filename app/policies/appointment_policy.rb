class AppointmentPolicy < ApplicationPolicy
  def show?
    admin? || company_owner? || client_owner?
  end

  def create? = user.present?

  def update? = admin? || company_owner?

  def confirm?   = admin? || company_owner?
  def cancel?    = admin? || company_owner? || client_owner?
  def complete?  = admin? || company_owner?
  def assign_employee? = admin? || company_owner?

  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.company_admin?
        scope.where(company: user.company)
      elsif user.client?
        scope.where(client_user: user)
      else
        scope.none
      end
    end
  end

  private

  def admin?         = user&.admin?
  def company_owner? = user&.company_admin? && record.company == user.company
  def client_owner?  = user&.client? && record.client_user == user
end
