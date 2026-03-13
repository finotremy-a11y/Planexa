class Company::SubscriptionsController < Company::BaseController
  def show
    @subscription = @company.subscription
  end
  def new; end
  def create; end
  def destroy; end
end
