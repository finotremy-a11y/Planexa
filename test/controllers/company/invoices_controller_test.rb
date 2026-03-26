# frozen_string_literal: true

require "test_helper"

class Company::InvoicesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user, :company_admin)
    @company = create(:company, user: @user)
    create(:subscription, company: @company, status: :active)
    sign_in @user

    @client = create(:user, role: :client)
    @service_type = create(:service_type, company: @company, price_cents: 5000)
    @appointment = create(:appointment, :confirmed,
      company: @company,
      service_type: @service_type,
      client_user: @client)
    @payment = create(:payment, :succeeded,
      appointment: @appointment,
      client_user: @client,
      company: @company,
      amount_cents: 5000)
    @invoice = create(:invoice,
      payment: @payment,
      company: @company,
      client_user: @client,
      issued_at: Time.zone.local(2026, 3, 12, 10, 0, 0))
  end

  test "redirige si non connecté" do
    sign_out @user
    get company_invoices_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si client" do
    sign_in create(:user, role: :client)
    get company_invoices_path
    assert_redirected_to root_path
  end

  test "GET index retourne 200" do
    get company_invoices_path
    assert_response :success
  end

  test "GET index filtre par mois et calcule les totaux" do
    april_payment = create(:payment, :succeeded,
      appointment: create(:appointment, :confirmed, company: @company, service_type: @service_type, client_user: @client),
      client_user: @client,
      company: @company,
      amount_cents: 8000)
    create(:invoice,
      payment: april_payment,
      company: @company,
      client_user: @client,
      subtotal_cents: 8000,
      tax_amount_cents: 1600,
      total_cents: 9600,
      issued_at: Time.zone.local(2026, 4, 3, 12, 0, 0))

    get company_invoices_path(year: 2026, month: 3)

    assert_response :success
    assert_equal 5000, assigns(:total_ht)
    assert_equal 1000, assigns(:total_tva)
    assert_equal 6000, assigns(:total_ttc)
    assert_equal [ @invoice ], assigns(:invoices).to_a
  end

  test "GET show retourne 200" do
    get company_invoice_path(@invoice)
    assert_response :success
  end

  test "GET show retourne 404 pour une autre entreprise" do
    other_user = create(:user, :company_admin)
    other_company = create(:company, user: other_user)
    other_invoice = create(:invoice, company: other_company)

    get company_invoice_path(other_invoice)
    assert_response :not_found
  end

  test "GET download envoie le PDF" do
    @invoice.pdf.attach(
      io: StringIO.new("fake pdf"),
      filename: "invoice.pdf",
      content_type: "application/pdf"
    )

    get download_company_invoice_path(@invoice)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], @invoice.invoice_number
  end

  test "GET download redirige si le PDF est absent" do
    get download_company_invoice_path(@invoice)

    assert_redirected_to company_invoice_path(@invoice)
    assert_equal "Le PDF de cette facture n'est pas encore disponible.", flash[:alert]
  end

  test "GET export_csv renvoie un CSV utf-8 avec entêtes et données" do
    get export_csv_company_invoices_path(year: 2026, month: 3)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "N° Facture"
    assert_includes response.body, @invoice.invoice_number
    assert_includes response.body, @client.full_name
  end
end