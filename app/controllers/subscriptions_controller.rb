class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :update, :destroy]

  # GET /subscriptions
  def index
    @subscriptions = Subscription.all
    render json: @subscriptions
    # namespaces = {
    #   "xmlns:xs" => "http://www.w3.org/2001/XMLSchema",
    #   "xmlns:wsdl" => "http://schemas.xmlsoap.org/wsdl/",
    #   "xmlns:tns" => "http://wasp.doi.soap.protocol.cellc.co.za",
    #   "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
    #   "xmlns:soap" => "http://schemas.xmlsoap.org/wsdl/soap/"
    # }
    # message = {
    #   :msisdn => "27841234447",
    #   :serviceName => "Soccer Scores",
    #   :contentProvider => "PSL",
    #   :chargeCode => "DOI001",
    #   :chargeInterval => "WEEKLY",
    #   :contentType => "OTHER",
    #   :bearerType => "WEB",
    #   :waspReference => "00",
    #   :waspTid => "QQChina"
    # }
    # client = Savon.client(endpoint: doi_endpoint, namespace: doi_ns, namespaces: namespaces, open_timeout: 600, read_timeout: 600, ssl_verify_mode: :none, wsse_auth: ["tenbew", "tenbew678"], namespace_identifier: :tns)
    # response = client.call(:add_subscription, soap_action: "tns:addSubscription", message: message)
    # logger.info "RESPONSE: #{response}"
  end

  # GET /subscriptions/1
  def show
    render json: @subscription
    # client = Savon.client(
    #   endpoint: 'http://41.156.64.242:8081/WaspInterface',
    #   namespace: 'http://wasp.doi.soap.protocol.cellc.co.za', namespaces: namespaces,
    #   wsse_auth: ["tenbew", "tenbew678"], open_timeout: 300, read_timeout: 300, ssl_verify_mode: :none
    # )
    # response = client.call(:charge_subscriber, soap_action: "tns:chargeSubscriber", :message => {:msisdn => "27841234447",:serviceID => "00",:waspTid => "QQChina"})
    # logger.info "RESPONSE: #{response}"
  end

  # POST /subscriptions
  def create
    @subscription = Subscription.new(subscription_params)

    if @subscription.save
      render json: @subscription, status: :created, location: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
    # response = doi_client.call(:add_subscription, soap_action: "wasp:addSubscription", message: doi_message)
    # logger.info "RESPONSE: #{response}"
  end

  # PATCH/PUT /subscriptions/1
  def update
    if @subscription.update(subscription_params)
      render json: @subscription
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
    # client = Savon.client do
    #   wsdl doi_wsdl
    #   namespaces doi_namespaces
    #   wsse_auth("tenbew", "tenbew678", :digest)
    # end
    # client = Savon.client(wsdl: doi_wsdl, namespace: doi_ns, namespaces: doi_namespaces, wsse_auth: ["tenbew", "tenbew678"], encoding: "UTF-8", convert_request_keys_to: :none, ssl_verify_mode: :none, pretty_print_xml: true, strip_namespaces: false)
    # client = Savon.client(wsdl: "DOI_SLB_Teraco.wsdl", ssl_verify_mode: :none, wsse_auth: ["tenbew", "tenbew678"], open_timeout: 600, read_timeout: 600)
    # response = client.call(:charge_subscriber, soap_action: "tns:chargeSubscriber", :message => {:msisdn => "27841234447",:serviceID => "00",:waspTid => "QQChina"})

    # message = {
    #   :msisdn => params[:msisdn],
    #   :serviceID => "CC123456",
    #   :waspTid => "123456"
    # }
    # response = client.call(:charge_subscriber, message: message)
    # logger.info "RESPONSE: #{response}"
  end

  # DELETE /subscriptions/1
  def destroy
    @subscription.destroy
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
    def doi_message
      {
        :msisdn => "27841234567",
        :serviceName => "Soccer Scores",
        :contentProvider => "PSL",
        :chargeCode => "OBS1014",
        :chargeInterval => "WEEKLY",
        :contentType => "OTHER",
        :bearerType => "WEB",
        :waspReference => "ABC123",
        :waspTid => "123456"
      }
    end

    def doi_client
      Savon.client(
        namespace: doi_ns,
        endpoint: doi_endpoint,
        namespaces: doi_namespaces,
        wsse_auth: ["tenbew", "tenbew678"],
        ssl_verify_mode: :none, ssl_version: :TLSv1,
        env_namespace: :soapenv, strip_namespaces: false,
        convert_request_keys_to: :none, pretty_print_xml: true
      )
    end

    def doi_wsdl
      "http://41.156.64.242:8081/WaspInterface?wsdl"
    end

    def doi_ns
      "http://wasp.doi.soap.protocol.cellc.co.za"
    end

    def doi_endpoint
      "http://41.156.64.242:8081/WaspInterface"
    end

    def doi_namespaces
      {
       "xmlns:xs" => "http://www.w3.org/2001/XMLSchema",
       "xmlns:wsdl" => "http://schemas.xmlsoap.org/wsdl/",
       "xmlns:tns" => "http://wasp.doi.soap.protocol.cellc.co.za",
       "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
       "xmlns:soap" => "http://schemas.xmlsoap.org/wsdl/soap/",
       "xmlns:ns2" => "http://wasp.doi.soap.protocol.cellc.co.za",
       "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
       "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za",
       "xmlns:wsse" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd",
       "xmlns:wsu" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
     }
    end

end
