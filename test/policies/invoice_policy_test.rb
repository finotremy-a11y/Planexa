require "test_helper"

class InvoicePolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @company_user = create(:user, :company_admin)
    @company = create(:company, user: @company_user)
    @client = create(:user, role: :client)

    @service_type = create(:service_type, company: @company)
    @appointment = create(:appointment, :confirmed,
      company: @company,
      service_type: @service_type,
      client_user: @client)
    @payment = create(:payment, :succeeded,
      appointment: @appointment,
      client_user: @client,
      company: @company)
    @invoice = create(:invoice,
      payment: @payment,
      company: @company,
      client_user: @client)

    @other_company_user = create(:user, :company_admin)
    @other_company = create(:company, user: @other_company_user)
    @other_client = create(:user, role: :client)
  end

  test "admin peut tout voir et exporter" do
    policy = InvoicePolicy.new(@admin, @invoice)
    assert policy.show?
    assert policy.download?
    assert policy.export_csv?
  end

  test "l'entreprise propriétaire peut voir et exporter" do
    policy = InvoicePolicy.new(@company_user, @invoice)
    assert policy.show?
    assert policy.download?
    assert policy.export_csv?
  end

  test "le client propriétaire peut voir et télécharger sans exporter" do
    policy = InvoicePolicy.new(@client, @invoice)
    assert policy.show?
    assert policy.download?
    assert_not policy.export_csv?
  end

  test "une autre entreprise ne peut pas accéder à la facture" do
    policy = InvoicePolicy.new(@other_company_user, @invoice)
    assert_not policy.show?
    assert_not policy.download?
    assert_not policy.export_csv?
  end

  test "un autre client ne peut pas accéder à la facture" do
    policy = InvoicePolicy.new(@other_client, @invoice)
    assert_not policy.show?
    assert_not policy.download?
    assert_not policy.export_csv?
  end

  test "scope admin retourne toutes les factures" do
    other_invoice = create(:invoice, company: @other_company)
    scope = InvoicePolicy::Scope.new(@admin, Invoice.all).resolve
    assert_includes scope, @invoice
    assert_includes scope, other_invoice
  end

  test "scope company_admin retourne seulement les factures de son entreprise" do
    other_invoice = create(:invoice, company: @other_company)
    scope = InvoicePolicy::Scope.new(@company_user, Invoice.all).resolve
    assert_includes scope, @invoice
    assert_not_includes scope, other_invoice
  end

  test "scope client retourne seulement ses factures" do
    other_invoice = create(:invoice, client_user: @other_client)
    scope = InvoicePolicy::Scope.new(@client, Invoice.all).resolve
    assert_includes scope, @invoice
    assert_not_includes scope, other_invoice
  end
end