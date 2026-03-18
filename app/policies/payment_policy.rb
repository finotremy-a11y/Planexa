class PaymentPolicy < ApplicationPolicy
  # Un paiement est visible par l'admin, le client concerné, ou l'entreprise concernée
  def show?
    admin? || client_owner? || company_owner?
  end

  # Seul le système (via webhook Stripe) crée les paiements, jamais via l'UI
  def create? = false
  def update? = false
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

  def admin?        = user&.admin?
  def client_owner? = user&.client? && record.client_user == user
  def company_owner? = user&.company_admin? && record.company == user.company
end
