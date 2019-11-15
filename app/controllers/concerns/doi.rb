module DOI
  class SubscriptionManager
    attr_reader :msisdn

    def initialize(msisdn)
      config = cellc_config
      @auth = config[:auth]
      @api = config[:api]
      @msisdn = msisdn
      @qq = qq_config
    end

    def subscribe
      message = {
        "msisdn" => @msisdn,
        "serviceName" => "Gaming",
        "contentProvider" => "QQ",
        "chargeCode" => @qq[:charge_code],
        "chargeInterval" => "DAILY",
        "contentType" => "ADULT",
        "bearerType" => "SMS",
        "waspReference" => @qq[:serviceID],
        "waspTID" => @qq[:waspTID]
      }

      response = client.call(:add_subscription, message: message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
        }
      })

      response.body[:add_subscription_response][:return]

    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def charge
      response = client.call(:charge_subscriber, message: charge_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
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
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
        }
      })
      response.body[:cancel_subscription_response]
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def notify
      response = client.call(:renotify_subscriber, message: notify_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
        }
      })
      response.body[:renotify_subscriber_response]
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    # Payloads

    def add_message
      # (Optional) MSISDN of the subscriber for which the service must be registered. The MSISDN must always be specified except in the case where the bearer set to WEB. (27841234567)
      msisdn = @msisdn

      # A unique service name that will be used to populate the DOI notification sent to a subscriber.
      service_name = "Gaming"

      # (Optional) An additional field that can be used to uniquely differentiate the service. This field, if provided, will also be used to populate the DOI notification sent to a subscriber. Applicable to aggregators.
      content_provider = "QQ" # || "PSL"

      # A valid charge code assigned to the WASP account. This will be provided by Cell C upon account creation.
      charge_code = @qq[:charge_code] || "DOI001"

      # The charge frequency applicable for this service
      charge_interval = "DAILY" # || "WEEKLY"

      # Type of the content this service will provide. ADULT or OTHER
      content_type = "OTHER" # || "ADULT"

      # Refer to Annexure A for bearer requirements
      bearer_type = "SMS" # || "WEB"

      # (Optional) A reference provided by the WASP associated with the service and returned in replies associated with this request
      wasp_reference = @qq[:serviceID] || "00"

      # Transaction id from WASP linked to this operation. This will be echoed back in the response
      wasp_tid = @qq[:waspTID] || "QQChina"

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
        :msisdn => @msisdn, # MSISDN of the subscriber to be charged
        :serviceID => @qq[:serviceID], # The serviceID identifying the service to be charged
        :waspTID => @qq[:waspTID] # Transaction id from WASP linked to this operation. This will be echoed back in the response
      }
    end

    def cancel_message
      {
        :msisdn => @msisdn,
        :waspTID => @qq[:waspTID],
        :serviceID => @qq[:serviceID]
      }
    end

    def notify_message
      {
        :msisdn => @msisdn, # MSISDN - MSISDN of the subscriber for which the service is registered
        :waspTID => @qq[:waspTID], # WaspTID - Transaction id from WASP linked to this operation. This will be echoed back in the response
        :serviceID => @qq[:serviceID] # (Optional) serviceID - The serviceID identifying the service to send the re-notify message to
      }
    end

    private

    def client
      Savon.client(
        wsdl: @api[:wsdl],
        endpoint: @api[:endpoint],
        namespace: @api[:namespace],
        namespaces: @api[:namespaces],
        wsse_auth: [@auth[:user], @auth[:pass]],
        element_form_default: :unqualified,
        namespace_identifier: :wasp,
        env_namespace: :soapenv,
        ssl_verify_mode: :none,
        logger: Rails.logger,
        log_level: :debug,
        log: true,
        encoding: "UTF-8",
        soap_version: 1,
        open_timeout: 900,
        read_timeout: 900,
        raise_errors: false,
        pretty_print_xml: true,
        strip_namespaces: true
      )
    end

    def qq_config
      qq_conf = TenbewDoiApi::Application.config.QQ_CONFIG[Rails.env]
      {
        :waspTID => qq_conf["waspTID"],
        :serviceID => qq_conf["serviceID"],
        :charge_code => qq_conf["charge_code"],
        :charge_value => qq_conf["charge_value"]
      }
    end

    def cellc_config
      if Rails.env.production?
        load_prod_config
      else
        load_default_config
      end
    end

    def operations
      client.operations
      # => [:renotify_subscriber, :charge_subscriber, :get_services, :request_position, :add_forced_subscription, :add_subscription, :cancel_subscription]
    end

    def load_prod_config
      cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
      {
        :auth => {
          :user => cellc_conf["user"],
          :pass => cellc_conf["pass"]
        },
        :api => {
          :wsdl => cellc_conf["wsdl"],
          :endpoint => cellc_conf["endpoint"],
          :namespace => cellc_conf["namespace"],
          :namespaces => {
            "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
            "xmlns:wsdl" => "http://schemas.xmlsoap.org/wsdl/",
            "xmlns:tns" => "http://doi.net.truteq.com/",
            "xmlns:soap" => "http://schemas.xmlsoap.org/wsdl/soap/",
            "xmlns:ns2" => "http://schemas.xmlsoap.org/soap/http",
            "xmlns:ns1" => "http://wasp.doi.soap.protocol.cellc.co.za"
          }
        },
        :web => {
          :callback_url => cellc_conf["callback_url"],
          :url => cellc_conf["url"] || cellc_conf["url_2"],
          :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
        },
        :charge_code => cellc_conf["charge_code"]
      }
    end

    def load_default_config
      cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
      {
        :auth => {
          :user => cellc_conf["user"] || doi_username,
          :pass => cellc_conf["pass"] || doi_password
        },
        :api => {
          :wsdl => cellc_conf["wsdl"] || doi_wsdl,
          :endpoint => cellc_conf["endpoint"] || doi_endpoint,
          :namespace => cellc_conf["namespace"] || doi_namespace,
          :namespaces => {
            "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
            "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
          }
        },
        :web => {
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

    # def load_default_config
    #   cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
    #   if cellc_conf["local_ssh_enabled"] == true
    #     {
    #       :auth => {
    #         :user => "tenbew", :pass => "tenbew678"
    #       },
    #       :api => {
    #         :wsdl => "http://localhost:8081/WaspInterface?wsdl",
    #         :endpoint => "http://localhost:8081/WaspInterface",
    #         :namespace => cellc_conf["namespace"] || doi_namespace,
    #         :namespaces => {
    #           "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
    #           "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
    #         }
    #       },
    #       :web => {
    #         :url => cellc_conf["url"],
    #         :callback_url => cellc_conf["callback_url"],
    #         :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
    #       }
    #     }
    #   else
    #     {
    #       :auth => {
    #         :user => cellc_conf["user"] || doi_username,
    #         :pass => cellc_conf["pass"] || doi_password
    #       },
    #       :api => {
    #         :wsdl => cellc_conf["wsdl"] || doi_wsdl,
    #         :endpoint => cellc_conf["endpoint"] || doi_endpoint,
    #         :namespace => cellc_conf["namespace"] || doi_namespace,
    #         :namespaces => {
    #           "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
    #           "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
    #         }
    #       },
    #       :web => {
    #         :url => cellc_conf["url"],
    #         :callback_url => cellc_conf["callback_url"],
    #         :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
    #       },
    #       :charge_codes => {
    #         "DOI001" => "R1",
    #         "DOI002" => "R2",
    #         "DOI003" => "R3",
    #         "DOI004" => "R4",
    #         "DOI005" => "R5"
    #       }
    #     }
    #   end
    # end

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
        "http://41.156.64.242:8081/WaspInterface?wsdl" || ENV["DOI_TEST_WSDL"]
      end
    end

    def doi_endpoint
      if Rails.env.production?
        "http://10.228.76.132:8081/WaspInterface" || ENV["DOI_LIVE_ENDPOINT"]
      else
        "http://41.156.64.242:8081/WaspInterface" || ENV["DOI_TEST_ENDPOINT"]
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

    # def client_1
    #   Savon.client(
    #     wsdl: doi_wsdl,
    #     endpoint: doi_endpoint,
    #     namespace: doi_namespace,
    #     namespaces: doi_namespaces,
    #     wsse_auth: ["#{doi_username}", "#{doi_password}"],
    #     namespace_identifier: :wasp,
    #     env_namespace: :soapenv,
    #     ssl_verify_mode: :none,
    #     encoding: "UTF-8",
    #     soap_version: 1,
    #     log: true,
    #     log_level: :debug,
    #     pretty_print_xml: true,
    #     strip_namespaces: false
    #   )
    # end

    # def cellc_config_current
    #   cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
    #   {
    #     :auth => {
    #       :user => cellc_conf["user"] || doi_username,
    #       :pass => cellc_conf["pass"] || doi_password
    #     },
    #     :api => {
    #       :wsdl => cellc_conf["wsdl"] || doi_wsdl,
    #       :endpoint => cellc_conf["endpoint"] || doi_endpoint,
    #       :namespace => cellc_conf["namespace"] || doi_namespace,
    #       :namespaces => {
    #         "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
    #         "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
    #       }
    #     },
    #     :web => {
    #       :url => cellc_conf["url"],
    #       :callback_url => cellc_conf["callback_url"],
    #       :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
    #     },
    #     :charge_codes => {
    #       "DOI001" => "R1",
    #       "DOI002" => "R2",
    #       "DOI003" => "R3",
    #       "DOI004" => "R4",
    #       "DOI005" => "R5"
    #     }
    #   }
    # end

    # def cellc_config
    #   cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
    #   if cellc_conf["local_ssh_enabled"] == true
    #     {
    #       :auth => {
    #         :user => "tenbew", :pass => "tenbew678"
    #       },
    #       :api => {
    #         :wsdl => "http://localhost:8081/WaspInterface?wsdl",
    #         :endpoint => "http://localhost:8081/WaspInterface",
    #         :namespace => cellc_conf["namespace"] || doi_namespace,
    #         :namespaces => {
    #           "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
    #           "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
    #         }
    #       },
    #       :web => {
    #         :url => cellc_conf["url"],
    #         :callback_url => cellc_conf["callback_url"],
    #         :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
    #       }
    #     }
    #   else
    #     {
    #       :auth => {
    #         :user => cellc_conf["user"] || doi_username,
    #         :pass => cellc_conf["pass"] || doi_password
    #       },
    #       :api => {
    #         :wsdl => cellc_conf["wsdl"] || doi_wsdl,
    #         :endpoint => cellc_conf["endpoint"] || doi_endpoint,
    #         :namespace => cellc_conf["namespace"] || doi_namespace,
    #         :namespaces => {
    #           "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
    #           "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
    #         }
    #       },
    #       :web => {
    #         :url => cellc_conf["url"],
    #         :callback_url => cellc_conf["callback_url"],
    #         :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
    #       },
    #       :charge_codes => {
    #         "DOI001" => "R1",
    #         "DOI002" => "R2",
    #         "DOI003" => "R3",
    #         "DOI004" => "R4",
    #         "DOI005" => "R5"
    #       }
    #     }
    #   end
    # end

  end
end
