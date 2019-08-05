module Api::V1
  class SubscriptionsController < ApiController
    before_action :set_subscription, only: [:show, :update, :destroy]

    # GET /api/v1/subscriptions
    def index
      render json: Subscription.all
    end

    # GET /api/v1/subscriptions/1
    def show
      render json: @subscription
    end

    # POST /api/v1/subscriptions
    def create
      @subscription = Subscription.new(subscription_params)

      if @subscription.save
        render json: @subscription, status: :created, location: @subscription
      else
        render json: @subscription.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/subscriptions/1
    def update
      if @subscription.update(subscription_params)
        render json: @subscription
      else
        render json: @subscription.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/subscriptions/1
    def destroy
      @subscription.destroy
    end

  private

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:state, :service, :msisdn, :message, :reference)
    end

  end
end
