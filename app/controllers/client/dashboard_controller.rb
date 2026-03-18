# frozen_string_literal: true

class Client::DashboardController < Client::BaseController
  def index
    @upcoming_appointments = current_user.client_appointments
                                          .upcoming
                                          .includes(:company, :service_type, :employee)
                                          .limit(5)
    @past_appointments     = current_user.client_appointments
                                          .past
                                          .includes(:company, :service_type, :employee)
                                          .limit(3)
  end
end
