require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @previous_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
    ActiveJob::Base.queue_adapter = @previous_queue_adapter
  end

  test "GET pages légales et contact retournent 200" do
    [
      cgu_path,
      cgv_path,
      confidentialite_path,
      mentions_legales_path,
      contact_path
    ].each do |path|
      get path
      assert_response :success
    end
  end

  test "POST contact envoie un email" do
    assert_emails 1 do
      post send_contact_path, params: {
        name: "Jean Dupont",
        email: "jean@example.fr",
        subject: "Question",
        message: "Bonjour, j'ai une question."
      }
    end

    assert_redirected_to contact_path
    follow_redirect!
    assert_match(/Message envoy[eé]/i, response.body)
  end

  test "POST contact invalide affiche une alerte" do
    post send_contact_path, params: {
      name: "",
      email: "",
      message: ""
    }

    assert_redirected_to contact_path
    follow_redirect!
    assert_match "Veuillez remplir tous les champs obligatoires", response.body
  end
end
