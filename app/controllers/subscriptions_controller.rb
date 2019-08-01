class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :update, :destroy]

  # GET /subscriptions
  def index
    @subscriptions = Subscription.all

    render json: @subscriptions
  end

  # GET /subscriptions/1
  def show
    render json: @subscription
  end

  # POST /subscriptions
  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      render json: @subscription, status: :created, location: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /subscriptions/1
  def update
    if @subscription.update(subscription_params)
      render json: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end

  # DELETE /subscriptions/1
  def destroy
    @subscription.destroy
  end

  def doi_config
    cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
    {
      :auth => {
        :username => cellc_conf["user"],
        :password => cellc_conf["pass"]
      },
      :endpoints => {
        :url => cellc_conf["url"],
        :callback_url => cellc_conf["callback_url"],
        :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
      },
      :charge_codes => {
        "DOI001" => "R1",
        "DOI002" => "R2",
        "DOI003" => "R3",
        "DOI004" => "R4",
        "DOI005" => "R5"
      }
    }
  end

  # def subscribe
  #   message = {
  #     :msisdn => "27841234567",
  #     :serviceName => "Soccer Scores",
  #     :contentProvider => "PSL",
  #     :chargeCode => "OBS1014",
  #     :chargeInterval => "WEEKLY",
  #     :contentType => "OTHER",
  #     :bearerType => "WEB",
  #     :waspReference => "ABC123",
  #     :waspTid => "123456"
  #   }
  #   response = client.call(:add_subscription, soap_action: "wasp:addSubscription", message: message)
  #   render :json => response.to_json
  # end
  # def charge
  #   message = {
  #     :msisdn => "27841234567",
  #     :serviceID => "CC123456",
  #     :waspTid => "123456"
  #   }
  #   response = client.call(:charge_subscriber, soap_action: "wasp:chargeSubscriber", message: message)
  #   render :json => response.to_json
  # end
  # def cancel
  #   render json: { error: 'No subscription found.' }, status: 401
  # end
  # def update
  #   subscriber = {
  #     :subscriber => {
  #       :mn => "CellC_ZA",
  #       :serviceID => "00",
  #       :waspTID => "QQChina",
  #       :msisdn => params[:msisdn]
  #     }
  #   }
  #   render :json => subscriber.to_json
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def subscription_params
      params.require(:subscription).permit(:state, :service, :msisdn, :message, :reference)
    end

    # def client
    #   Savon.client(wsdl: api_wsdl, namespace: api_ns, namespaces: api_namespaces, encoding: "UTF-8", convert_request_keys_to: :none, ssl_verify_mode: :none, pretty_print_xml: true, strip_namespaces: false)
    # end
    # def api_ns
    #   "http://wasp.doi.soap.protocol.cellc.co.za"
    # end
    # def api_wsdl
    #   "http://wasp.doi.soap.protocol.cellc.co.za?wsdl"
    # end
    # def api_namespaces
    #   {
    #     "xmlns:ns2" => "http://wasp.doi.soap.protocol.cellc.co.za",
    #     "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
    #     "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za",
    #     "xmlns:wsse" => "http://docs.oasis-open.org/wss/2004/01/oasis-
    #     200401-wss-wssecurity-secext-1.0.xsd",
    #     "xmlns:wsu" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    #   }
    # end

end
