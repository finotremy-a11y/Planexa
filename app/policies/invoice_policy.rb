# frozen_string_literal: true

class InvoicePolicy < ApplicationPolicy
  def index?
    admin? || company_owner? || client_owner?
  end

  def show?
    admin? || company_owner? || client_owner?
  end

  def download?
    show?
  end

  def export_csv?
    admin? || company_owner?
  end

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

  def admin?
    user&.admin?
  end

  def client_owner?
    user&.client? && record.client_user == user
  end

  def company_owner?
    user&.company_admin? && record.company == user.company
  end
end
