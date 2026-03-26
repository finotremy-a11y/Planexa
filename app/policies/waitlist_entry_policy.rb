class WaitlistEntryPolicy < ApplicationPolicy
  def index?   = admin? || company_owner?
  def show?    = admin? || company_owner?
  def destroy? = admin? || company_owner?

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

  def admin?         = user&.admin?
  def company_owner? = user&.company_admin? && record.company == user.company
end
