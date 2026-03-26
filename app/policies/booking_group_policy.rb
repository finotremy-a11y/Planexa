# frozen_string_literal: true

class BookingGroupPolicy < ApplicationPolicy
  # Lecture : admin, owner entreprise du groupe, ou client propriétaire
  def show?
    admin? || company_owner? || client_owner?
  end

  # Création publique (clients anonymes ou connectés)
  def create? = true

  # Annulation : admin, company_owner ou client_owner tant que pending/confirmed
  def cancel?
    (admin? || company_owner? || client_owner?) && cancellable?
  end

  # Seul l'admin peut détruire physiquement
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
  def cancellable?   = record.pending? || record.confirmed?
end
