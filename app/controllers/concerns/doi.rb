module DOI
  class SubscriptionManager
    attr_reader :msisdn, :token

    def initialize(msisdn)
      @msisdn = msisdn || "27842333777"
      # can be removed once tested
      @token = token
      @nonce = nonce
      @timestamp = timestamp
    end

    def client
      Savon.client(
        wsdl: doi_wsdl,
        endpoint: doi_endpoint,
        namespace: doi_namespace,
        namespaces: doi_namespaces,
        wsse_auth: ["#{doi_username}", "#{doi_password}"],
        element_form_default: :unqualified,
        namespace_identifier: :wasp,
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        logger: Rails.logger,
        log_level: :debug,
        log: true,
        encoding: "UTF-8",
        soap_version: 1,
        open_timeout: 600,
        read_timeout: 600,
        raise_errors: false,
        pretty_print_xml: true,
        strip_namespaces: true
      )
    end

    def subscribe
      response = client.call(:add_subscription, message: add_subscription_payload, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{doi_username}",
          "Password" => "#{doi_password}"
        }
      })
      response.body[:add_subscription_response][:return]
        #=> {:result=>"0", :service_id=>"3345388", :wasp_reference=>"00", :wasp_tid=>"QQChina"}
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def charge
      response = client.call(:charge_subscriber, message: charge_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{doi_username}",
          "Password" => "#{doi_password}"
        }
      })
      response.body[:charge_subscriber_response][:return]
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def cancel
      response = client.call(:cancel_subscription, message: cancel_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{doi_username}",
          "Password" => "#{doi_password}"
        }
      })
      response.body[:cancel_subscription_response]
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    # Payloads

    def add_subscription_payload
      # (Optional) MSISDN of the subscriber for which the service must be registered. The MSISDN must always be specified except in the case where the bearer set to WEB. (27841234567)
      msisdn = @msisdn # || "27841234567"

      # A unique service name that will be used to populate the DOI notification sent to a subscriber.
      service_name = "Soccer Scores"

      # (Optional) An additional field that can be used to uniquely differentiate the service. This field, if provided, will also be used to populate the DOI notification sent to a subscriber. Applicable to aggregators.
      content_provider = "PSL"

      # A valid charge code assigned to the WASP account. This will be provided by Cell C upon account creation.
      charge_code = "DOI001"

      # The charge frequency applicable for this service
      charge_interval = "WEEKLY"

      # Type of the content this service will provide. ADULT or OTHER
      content_type = "OTHER"

      # Refer to Annexure A for bearer requirements
      bearer_type = "WEB"

      # (Optional) A reference provided by the WASP associated with the service and returned in replies associated with this request
      wasp_reference = "00"

      # Transaction id from WASP linked to this operation. This will be echoed back in the response
      wasp_tid = "QQChina"

      # addSubscription payload
      {
        "msisdn" => msisdn,
        "serviceName" => service_name,
        "contentProvider" => content_provider,
        "chargeCode" => charge_code,
        "chargeInterval" => charge_interval,
        "contentType" => content_type,
        "bearerType" => bearer_type,
        "waspReference" => wasp_reference,
        "waspTID" => wasp_tid
      }
    end

    def charge_message
      {
        :msisdn => @msisdn,
        :waspTID => "QQChina",
        :serviceID => "00"
      }
    end

    def cancel_message
      {
        :msisdn => @msisdn,
        :waspTID => "QQChina",
        :serviceID => "00"
      }
    end

    # Clients

    def client_1
      Savon.client(
        wsdl: doi_wsdl,
        endpoint: doi_endpoint,
        namespace: doi_namespace,
        namespaces: doi_namespaces,
        wsse_auth: ["#{doi_username}", "#{doi_password}"],
        namespace_identifier: :wasp,
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        encoding: "UTF-8",
        soap_version: 1,
        log: true,
        log_level: :debug,
        pretty_print_xml: true,
        strip_namespaces: false
      )
    end

    def client_2
      user = doi_username
      pass = doi_password

      # set headers
      soap_header = <<-HEREDOC
       <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss- wssecurity-utility-1.0.xsd">
         <wsse:UsernameToken wsu:Id="UsernameToken-#{@token}">
           <wsse:Username>#{user}</wsse:Username>
           <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">#{pass}</wsse:Password>
           <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">#{Base64.encode64(@nonce).chomp}</wsse:Nonce>
           <wsu:Created>#{@timestamp}</wsu:Created>
         </wsse:UsernameToken>
       </wsse:Security>
       <wasp:ServiceAuth>
         <Username>#{user}</Username>
         <Password>#{pass}</Password>
       </wasp:ServiceAuth>
      HEREDOC

      # clear the nonce after each use
      @nonce = nil

      # initialize client
      Savon.client(
          wsdl: "#{doi_wsdl}",
          env_namespace: 'soapenv',
          soap_header: soap_header,
          namespace_identifier: :wasp,
          ssl_verify_mode: :none,
          pretty_print_xml: true,
          log_level: :debug,
          log: true,
          raise_errors: false
      )
    end

    def client_3
      Savon.client(
        wsdl: doi_wsdl,
        endpoint: doi_endpoint,
        namespace: doi_namespace,
        soap_header: basic_wsse_headers,
        ssl_verify_mode: :none,
        env_namespace: :soapenv,
        namespace_identifier: :wasp,
        convert_request_keys_to: :none,
        strip_namespaces: false,
        pretty_print_xml: true,
        raise_errors: false,
        log_level: :debug,
        log: true
      )
    end

    def client_4
      Savon.client(
        wsdl: doi_wsdl,
        endpoint: doi_endpoint,
        namespace: doi_namespace,
        namespaces: doi_namespaces,
        ssl_verify_mode: :none,
        env_namespace: :soapenv,
        namespace_identifier: :wasp,
        element_form_default: :unqualified,
        convert_request_keys_to: :camelcase,
        log: true,
        log_level: :debug,
        soap_version: 1,
        open_timeout: 600,
        read_timeout: 600,
        raise_errors: false,
        pretty_print_xml: true,
        strip_namespaces: true
      )
    end

    # Endpoints

    def subscribe_1
      client = Savon.client(
        wsdl: doi_wsdl,
        ssl_verify_mode: :none,
        env_namespace: :soapenv,
        namespace_identifier: :wasp,
        pretty_print_xml: true,
        log_level: :debug,
        log: true
      )

      xml = <<-HEREDOC
       <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wasp="http://wasp.doi.soap.protocol.cellc.co.za">
         <soapenv:Header>
           <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" soapenv:mustUnderstand="1">
             <wsse:UsernameToken wsu:Id="UsernameToken-1">
               <wsse:Username>tenbew</wsse:Username>
               <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">tenbew678</wsse:Password>
             </wsse:UsernameToken>
           </wsse:Security>
           <wasp:ServiceAuth>
             <Username>tenbew</Username>
             <Password>tenbew678</Password>
           </wasp:ServiceAuth>
         </soapenv:Header>
         <soapenv:Body>
           <wasp:addSubscription>
             <msisdn>0734541628</msisdn>
             <serviceName>Soccer Scores</serviceName>
             <contentProvider>PSL</contentProvider>
             <chargeCode>DOI001</chargeCode>
             <chargeInterval>WEEKLY</chargeInterval>
             <contentType>OTHER</contentType>
             <bearerType>WEB</bearerType>
             <waspReference>00</waspReference>
             <waspTID>QQChina</waspTID>
           </wasp:addSubscription>
         </soapenv:Body>
       </soapenv:Envelope>
      HEREDOC

      response = client.call(:add_subscription, xml: xml, :soap_action => "")
      puts "RESPONSE: #{response}"
      response.body
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def charge_1
      client_1.call(:charge_subscriber, message: charge_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{doi_username}",
          "Password" => "#{doi_password}"
        }
      })
    rescue Savon::SOAPFault => error
      puts "ERROR: #{error}"
      fault_code = error.to_hash[:fault][:faultcode]
      raise StandardError, fault_code
    end

    # Manually inserting WSSE headers
    def subscribe_2
      response = client_2.call(:add_subscription, message: add_subscription_payload, :soap_action => "")
      puts "RESPONSE: #{response}"
      response.body
      # response.body[:fault][:faultstring]
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      fault_message = error.to_hash[:fault][:faultstring]
      puts "ERROR :: MESSAGE: #{fault_message}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def charge_2
      client_2.call(:charge_subscriber, message: charge_message, :soap_action => "")
    rescue Savon::SOAPFault => error
      puts "ERROR: #{error}"
      fault_code = error.to_hash[:fault][:faultcode]
      raise StandardError, fault_code
    end

    # Manually generating WSSE headers - basic
    def subscribe_3
      response = client_3.call(:add_subscription, message: add_subscription_payload, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{doi_username}",
          "Password" => "#{doi_password}"
        }
      })
      puts "RESPONSE: #{response}"
      response.body
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      fault_message = error.to_hash[:fault][:faultstring]
      puts "ERROR :: MESSAGE: #{fault_message}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def charge_3
      response = client_3.call(:charge_subscriber, message: charge_message, :soap_action => "")
      puts "RESPONSE: #{response}"
      response.body
    rescue Savon::SOAPFault => error
      puts "ERROR: #{error}"
      fault_code = error.to_hash[:fault][:faultcode]
      raise StandardError, fault_code
    end

    # Manually generating WSSE headers - digest
    def subscribe_4
      response = client_4.call(:add_subscription, message: add_subscription_payload, :soap_action => "", soap_header: digest_wsse_headers)
      puts "RESPONSE: #{response}"
      response.body#[:response]
    rescue Savon::SOAPFault => error
      puts "ERROR: #{error}"
      fault_code = error.to_hash[:fault][:faultcode]
      raise StandardError, fault_code
    end

    # Headers

    def basic_wsse_headers
      {
        "wsse:Security" => {
          "@soapenv:mustUnderstand" => "1",
          "@xmlns:wsse" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd",
          "@xmlns:wsu" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd",
          "wsse:UsernameToken" => {
            "@wsu:Id" => "UsernameToken-#{@token}",
            "wsse:Username"  => doi_username,
            "wsse:Password" => doi_password,
            :attributes! => {
              "wsse:Password" => { "Type" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText" }
            }
          }
        }
      }
    end

    def digest_wsse_headers
      {
        "wsse:Security" => {
          "@soapenv:mustUnderstand" => "1",
          "@xmlns:wsse" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd",
          "@xmlns:wsu" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd",
          "wsse:UsernameToken" => {
              "@wsu:Id" => "UsernameToken-#{@token}",
              "wsse:Username"  => doi_username,
              "wsse:Nonce"  => Base64.encode64(nonce).chomp,
              "wsu:Created" => timestamp,
              "wsse:Password" => digest_password,
              :attributes! => {
                "wsse:Password" => { "Type" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest" },
                "wsse:Nonce" => { "EncodingType" => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary" }
            }
          }
        }
      }
    end

    def soap_header
      {
        "wasp:ServiceAuth" => {
          "Username" => "#{doi_username}",
          "Password" => "#{doi_password}"
        }
      }
    end

    private

    def digest_password
      token = nonce + timestamp + doi_password
      Base64.encode64(Digest::SHA1.digest(token)).chomp!
    end

    def nonce
      @nonce ||= Digest::SHA1.hexdigest random_string + timestamp
    end

    def random_string
      (0...100).map { ("a".."z").to_a[rand(26)] }.join
    end

    def timestamp
      @timestamp ||= Time.now.utc.xmlschema
    end

    def token
      @token ||= 0
      @token += 1
    end

    protected

    def doi_username
      if Rails.env.production?
        cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
        cellc_conf["user"]
      else
        "tenbew"
      end
    end

    def doi_password
      if Rails.env.production?
        cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
        cellc_conf["pass"]
      else
        "tenbew678"
      end
    end

    def doi_wsdl
      if Rails.env.production?
        "http://10.228.76.132:8081/WaspInterface?wsdl" || ENV["DOI_LIVE_WSDL"]
      else
        "http://41.156.64.242:8081/WaspInterface?wsdl" || ENV["DOI_TEST_WSDL"] # "http://localhost:8081/WaspInterface?wsdl"
      end
    end

    def doi_endpoint
      if Rails.env.production?
        "http://10.228.76.132:8081/WaspInterface" || ENV["DOI_LIVE_ENDPOINT"]
      else
        "http://41.156.64.242:8081/WaspInterface" || ENV["DOI_TEST_ENDPOINT"] # "http://localhost:8081/WaspInterface"
      end
    end

    def doi_namespace
      if Rails.env.production?
        "http://doi.net.truteq.com/" || ENV["DOI_LIVE_NAMESPACE"]
      else
        "http://wasp.doi.soap.protocol.cellc.co.za" || ENV["DOI_TEST_NAMESPACE"]
      end
    end

    def doi_namespaces
      if Rails.env.production?
        {
          "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
          "xmlns:wsdl" => "http://schemas.xmlsoap.org/wsdl/",
          "xmlns:tns" => "http://doi.net.truteq.com/",
          "xmlns:soap" => "http://schemas.xmlsoap.org/wsdl/soap/",
          "xmlns:ns2" => "http://schemas.xmlsoap.org/soap/http",
          "xmlns:ns1" => "http://wasp.doi.soap.protocol.cellc.co.za"
        }
      else
        {"xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/","xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"}
      end
    end

  end
end
