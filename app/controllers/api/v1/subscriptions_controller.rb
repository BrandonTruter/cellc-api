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

    # TODO: Refactor all integration to seperate class, move all endpoints to config
    # Have to manually generate WSSE headers, savon wsse_auth doesnt allow required customization
    WSU_NAMESPACE  = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    WSSE_NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    PASSWORD_TYPE  = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
    NONCE_ENCODING = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
    DOI_NAMESPACE  = "http://wasp.doi.soap.protocol.cellc.co.za"
    DOI_NAMESPACES = {
      "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
      "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
    }
    TIMESTAMP = "2019-08-13T12:10:15.061Z" # JUST FOR TESTING
    WSDL = "http://41.156.64.242:8081/WaspInterface?wsdl"
    ENDP = "http://41.156.64.242:8081/WaspInterface"
    PASS = "tenbew678"
    USER = "tenbew"

    def add_sub
      logger.info "Api::V1::SubscriptionsController.add_sub"

      message = {
        :msisdn => "27842333777",
        :serviceName => "Banking",
        :contentProvider => "ABSA",
        :chargeCode => "DOI005",
        :chargeInterval => "WEEKLY",
        :contentType => "OTHER",
        :bearerType => "WEB",
        :waspReference => "CellC_ZA",
        :waspTid => "QQChina"
      }

      response = cellc_client.call(:add_subscription) do
        soap_header "wasp:ServiceAuth" => {
                        "Username" => USER,
                        "Password" => PASS
                      }
        message message
      end

      logger.info "RESP: #{response}"

      render :json => response.to_json
    end

    def charge_sub
      logger.info "Api::V1::SubscriptionsController.charge_sub"

      client = Savon.client(
        wsdl: WSDL,
        endpoint: ENDP,
        namespace: DOI_NAMESPACE,
        namespaces: DOI_NAMESPACES,
        namespace_identifier: :tns,
        wsse_auth: [USER, PASS],
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        pretty_print_xml: true,
        raise_errors: false,
        logger: Rails.logger,
        log_level: :debug,
        log: true
      )

      charge_message = {
        :msisdn => "27842333777",
        :waspTID => "QQChina",
        :serviceID => "00"
      }

      response = client.call(:charge_subscriber) do
        soap_header "wasp:ServiceAuth" => {
                        "Username" => "#{USER}",
                        "Password" => "#{PASS}"
                      }
        message charge_message
      end

      logger.info "RESP: #{response}"

      render :json => response.to_json
    end

    def cancel_sub
      logger.info "Api::V1::SubscriptionsController.cancel_sub"

      message = {
        :msisdn => "27842333777",
        :waspTID => "QQChina",
        :serviceID => "00"
      }

      client = Savon.client(
        wsdl: "#{WSDL}",
        namespace: DOI_NAMESPACE,
        namespaces: doi_namespaces,
        wsse_auth: ["tenbew", "tenbew678", :digest],
        convert_request_keys_to: :none,
        namespace_identifier: :wasp,
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        open_timeout: 400,
        read_timeout: 400,
        log: true,
        log_level: :debug,
        logger: Rails.logger,
        strip_namespaces: false,
        pretty_print_xml: true
      )

      response = client.call(:cancel_subscription, :message => message)

      logger.info "RESPONSE: #{response}"

      render :json => response.to_json
    end

    def cellc_client
      Savon.client(
        wsdl: WSDL,
        endpoint: ENDP,
        namespace: DOI_NAMESPACE,
        namespaces: DOI_NAMESPACES,
        soap_header: cellc_headers,
        namespace_identifier: :wasp,
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        pretty_print_xml: true,
        logger: Rails.logger,
        log_level: :debug,
        log: true
      )
    end

    def cellc_headers
      ts = generate_timestamp()
      {
        "wsse:Security" => {
          "@soapenv:mustUnderstand" => "1",
          "@xmlns:wsse" => WSSE_NAMESPACE,
          "@xmlns:wsu" => WSU_NAMESPACE,
          "wsse:UsernameToken" => {
            "@wsu:Id" => "UsernameToken-8",
            "wsse:Nonce"  => generate_nonce(ts),
            "wsu:Created" => ts,
            "wsse:Username"  => USER,
            "wsse:Password"  => PASS,
            :attributes! => {
              "wsse:Nonce" => { "EncodingType" => NONCE_ENCODING },
              "wsse:Password" => { "Type" => PASSWORD_TYPE }
            }
          }
        }
      }
    end

    def generate_timestamp()
      TIMESTAMP || Time.now
    end

    def generate_nonce(ts)
      Digest::SHA1.hexdigest random_string + ts
    end

    def random_string
      (0...100).map { ("a".."z").to_a[rand(26)] }.join
    end

  private

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:state, :service, :msisdn, :message, :reference)
    end

    # DOI Configuration

    def doi_client
      Savon.client(
        wsdl: "#{WSDL}",
        namespace: DOI_NAMESPACE,
        namespaces: doi_namespaces,
        wsse_auth: ["tenbew", "tenbew678", :digest],
        convert_request_keys_to: :none,
        namespace_identifier: :wasp,
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        open_timeout: 300,
        read_timeout: 300,
        log: true,
        log_level: :debug,
        logger: Rails.logger,
        strip_namespaces: false,
        pretty_print_xml: true
      )
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

    def subscriber
      {
        :subscriber => {
          :mn => "CellC_ZA",
          :serviceID => "00",
          :waspTID => "QQChina",
          :msisdn => "0873248237"
        }
      }
    end

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
end
