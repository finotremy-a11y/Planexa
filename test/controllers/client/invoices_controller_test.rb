# frozen_string_literal: true

require "test_helper"

class Client::InvoicesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client = create(:user, role: :client)
    sign_in @client

    @company = create(:company)
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
      client_user: @client)
  end

  test "redirige si non connecté" do
    sign_out @client
    get client_invoices_path
    assert_redirected_to new_user_session_path
  end

  test "redirige si company_admin" do
    sign_in create(:user, :company_admin)
    get client_invoices_path
    assert_redirected_to root_path
  end

  test "GET index retourne 200" do
    get client_invoices_path
    assert_response :success
  end

  test "GET index n'affiche que les factures du client courant" do
    other_client = create(:user, role: :client)
    other_company = create(:company)
    other_service = create(:service_type, company: other_company)
    other_appointment = create(:appointment, :confirmed, company: other_company, service_type: other_service, client_user: other_client)
    other_payment = create(:payment, :succeeded, appointment: other_appointment, client_user: other_client, company: other_company)
    other_invoice = create(:invoice, payment: other_payment, company: other_company, client_user: other_client)

    get client_invoices_path

    assert_response :success
    assert_includes assigns(:invoices).to_a, @invoice
    assert_not_includes assigns(:invoices).to_a, other_invoice
  end

  test "GET show retourne 200" do
    get client_invoice_path(@invoice)
    assert_response :success
  end

  test "GET show redirige si la facture ne lui appartient pas" do
    other_client = create(:user, role: :client)
    other_company = create(:company)
    other_service = create(:service_type, company: other_company)
    other_appointment = create(:appointment, :confirmed, company: other_company, service_type: other_service, client_user: other_client)
    other_payment = create(:payment, :succeeded, appointment: other_appointment, client_user: other_client, company: other_company)
    other_invoice = create(:invoice, payment: other_payment, company: other_company, client_user: other_client)

    get client_invoice_path(other_invoice)

    assert_redirected_to client_invoices_path
    assert_equal "Facture introuvable.", flash[:alert]
  end

  test "GET download envoie le PDF" do
    @invoice.pdf.attach(
      io: StringIO.new("fake pdf"),
      filename: "invoice.pdf",
      content_type: "application/pdf"
    )

    get download_client_invoice_path(@invoice)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert_includes response.headers["Content-Disposition"], @invoice.invoice_number
  end

  test "GET download redirige si le PDF est absent" do
    get download_client_invoice_path(@invoice)

    assert_redirected_to client_invoice_path(@invoice)
    assert_equal "Le PDF de cette facture n'est pas encore disponible.", flash[:alert]
  end
end