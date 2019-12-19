module Api::V1
  class SubscriptionsController < ApiController
    before_action :set_subscription, only: [:show, :update, :destroy]
    before_action :set_subscriber, only: [:charge, :cancel_sub, :notify_sub]
    before_action :set_params, only: [:add_sub, :charge_sub, :charge, :cancel_sub, :notify_sub]

    # POST /api/v1/add_sub
    def add_sub
      logger.info "Api::V1::SubscriptionsController.add_sub : #{@msisdn}"
      response = DOI::SubscriptionManager.new(@msisdn).subscribe
      logger.info "RESPONSE: #{response}"

      render :json => response.to_json
    end

    # POST /api/v1/charge_sub
    def charge_sub
      logger.info "Api::V1::SubscriptionsController.charge_sub : #{@msisdn}"
      response = DOI::SubscriptionManager.new(@msisdn).charge
      logger.info "RESPONSE: #{response}"

      render :json => response.to_json
    end

    # POST /api/v1/cancel_sub
    def cancel_sub
      logger.info "Api::V1::SubscriptionsController.cancel_sub : #{@msisdn}"
      if @subscriber.nil? && @service_id.nil?
        response = DOI::SubscriptionManager.new(@msisdn).cancel
      else
        response = @subscriber.cancel_subscription(@service_id)
      end
      logger.info "RESPONSE: #{response}"

      render :json => response.to_json
    end

    # POST /api/v1/notify_sub
    def notify_sub
      logger.info "Api::V1::SubscriptionsController.notify_sub : #{@msisdn}"
      # response = DOI::SubscriptionManager.new(@msisdn).notify
      response = @subscriber.notify(@service_id)
      logger.info "RESPONSE: #{response}"

      render :json => response.to_json
    end

    # POST /api/v1/charge
    def charge
      logger.info "Api::V1::SubscriptionsController.charge"
      # subscriber = DOI::SubscriptionManager.new(msisdn)
      sub = @subscriber.nil? ? DOI::SubscriptionManager.new(@msisdn) : @subscriber
      service_id = @service_id.nil? ? params[:service_id] : @service_id
      logger.info "msisdn: #{msisdn}, service_id: #{service_id}"
      # response = subscriber.charge_subscription(service_id)
      response = sub.charge_subscription(service_id)
      logger.info "RESPONSE: #{response}"

      render :json => response.to_json
    end


    # REST ENDPOINTS

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

    def set_params
      @msisdn = params[:msisdn]
    end

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:state, :service, :msisdn, :message, :reference)
    end

    def set_subscriber
      msisdn = @msisdn.nil? ? params[:msisdn] : @msisdn
      @subscriber = DOI::SubscriptionManager.new(msisdn)
      @service_id = params[:service_id] unless params[:service_id].nil?
    end
  end
end
