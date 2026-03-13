class SubscriptionPolicy < ApplicationPolicy
  def show?    = admin? || company_owner?
  def create?  = company_owner? && !subscription_exists?
  def destroy? = admin? || company_owner?

  private

  def admin?         = user&.admin?
  def company_owner? = user&.company_admin? && record.company == user.company
  def subscription_exists? = user.company&.subscription&.active? || user.company&.subscription&.trialing?
end
