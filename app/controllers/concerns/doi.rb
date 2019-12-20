module DOI
  class SubscriptionManager
    # attr_reader :msisdn

    def initialize(msisdn)
      config = cellc_config
      @auth = config[:auth]
      @api = config[:api]
      @msisdn = msisdn
      @qq = qq_config
    end

    def subscribe
      response = client.call(:add_subscription, message: add_sub_message, :soap_action => "", :soap_header => {
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

    def notify(service_id)
      message = notify_message(service_id)
      response = client.call(:renotify_subscriber, message: message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
        }
      })
      response.body[:renotify_subscriber_response][:return]
    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def charge_subscription(service_id = nil)
      message = { :msisdn => @msisdn, :serviceID => service_id, :waspTID => @qq[:waspTID] }
      response = client.call(:charge_subscriber, message: message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}", "Password" => "#{@auth[:pass]}"
        }
      })
      response.body[:charge_subscriber_response][:return]
    rescue Savon::SOAPFault => error
      raise StandardError, error.to_hash[:fault][:faultcode]
    end

    def cancel_subscription(service_id)
      response = client.call(:cancel_subscription, message: cancel_message(service_id), :soap_action => "", :soap_header => {
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

    # Payloads

    def add_sub_message
      # (Optional) MSISDN of the subscriber for which the service must be registered. The MSISDN must always be specified except in the case where the bearer set to WEB. (27841234567)
      msisdn = @msisdn
      # A unique service name that will be used to populate the DOI notification sent to a subscriber.
      service_name = "QQ-Tenbew Games" # || "Gaming"

      # (Optional) An additional field that can be used to uniquely differentiate the service. This field, if provided, will also be used to populate the DOI notification sent to a subscriber. Applicable to aggregators.
      content_provider = "Tenbew" # || "QQ"

      # A valid charge code assigned to the WASP account. This will be provided by Cell C upon account creation.
      charge_code = @qq[:charge_code] # || "DOI001"

      # The charge frequency applicable for this service
      charge_interval = "DAILY" # || "WEEKLY"

      # Type of the content this service will provide. ADULT or OTHER
      content_type = "ADULT" # || "OTHER"

      # Refer to Annexure A for bearer requirements
      bearer_type = "SMS" # || "WEB"

      # (Optional) A reference provided by the WASP associated with the service and returned in replies associated with this request
      wasp_reference = @qq[:serviceID] || "00"

      # Transaction id from WASP linked to this operation. This will be echoed back in the response
      wasp_tid = @qq[:waspTID] || "QQChina"

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

    def cancel_message(service_id = nil)
      {
        :msisdn => @msisdn,
        :waspTID => @qq[:waspTID],
        :serviceID => service_id || @qq[:serviceID]
      }
    end

    def notify_message(service_id)
      {
        :msisdn => @msisdn, # MSISDN - MSISDN of the subscriber for which the service is registered
        :waspTID => @qq[:waspTID], # WaspTID - Transaction id from WASP linked to this operation. This will be echoed back in the response
        :serviceID => service_id || @qq[:serviceID] # (Optional) serviceID - The serviceID identifying the service to send the re-notify message to
      }
    end

    def test_doi_operations(wasp_ref, wasp_tid)
      add_message = {
        "msisdn" => @msisdn,
        "serviceName" => "QQ-Tenbew Games",
        "contentProvider" => "Tenbew",
        "chargeCode" => @qq[:charge_code],
        "chargeInterval" => "DAILY",
        "contentType" => "ADULT",
        "bearerType" => "SMS",
        "waspReference" => wasp_ref,
        "waspTID" => wasp_tid
      }
      addsub_response = client.call(:add_subscription, message: add_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
        }
      })
      response = addsub_response.body[:add_subscription_response]
      puts "AddSubscription Response: #{response}"

      charge_message = {
        :msisdn => @msisdn,
        :serviceID => response[:return][:service_id],
        :waspTid => wasp_tid
      }
      charge_response = client.call(:charge_subscriber, message: charge_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}", "Password" => "#{@auth[:pass]}"
        }
      })
      puts "ChargeSubscription Response: #{charge_response.body[:charge_subscriber_response]}"

    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    def test_prod_operations(wasp_ref, wasp_tid)
      add_message = {
        "msisdn" => @msisdn,
        "serviceName" => "QQ-Tenbew Games",
        "contentProvider" => "Tenbew",
        "chargeCode" => @qq[:charge_code],
        "chargeInterval" => "DAILY",
        "contentType" => "ADULT",
        "bearerType" => "SMS",
        "waspReference" => wasp_ref,
        "waspTID" => wasp_tid
      }
      addsub_response = prod_client.call(:add_subscription, message: add_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}",
          "Password" => "#{@auth[:pass]}"
        }
      })
      response = addsub_response.body[:add_subscription_response]
      puts "AddSubscription Response: #{response}"

      charge_message = {
        :msisdn => @msisdn,
        :serviceID => response[:return][:service_id],
        :waspTid => wasp_tid
      }
      charge_response = prod_client.call(:charge_subscriber, message: charge_message, :soap_action => "", :soap_header => {
        'wasp:ServiceAuth' => {
          "Username" => "#{@auth[:user]}", "Password" => "#{@auth[:pass]}"
        }
      })
      puts "ChargeSubscription Response: #{charge_response.body[:charge_subscriber_response]}"

    rescue Savon::SOAPFault => error
      fault_code = error.to_hash[:fault][:faultcode]
      puts "ERROR: #{error}, CODE: #{fault_code}"
      raise StandardError, fault_code
    end

    private

    def client
      if Rails.env.production?
        prod_client
      else
        dev_client
      end
    end

    def dev_client
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

    def prod_client
      Savon.client(
        wsdl: @api[:wsdl],
        endpoint: @api[:endpoint],
        namespace: @api[:namespace],
        namespaces: @api[:namespaces],
        wsse_auth: [@auth[:user], @auth[:pass]],
        ssl_verify_mode: :none, ssl_version: :TLSv1,
        log: true, logger: Rails.logger, log_level: :info,
        namespace_identifier: :wasp, env_namespace: :soapenv,
        element_form_default: :unqualified, encoding: "UTF-8",
        raise_errors: true, pretty_print_xml: true, strip_namespaces: true
      )
    end

    # def client
    #   Savon.client(
    #     wsdl: @api[:wsdl],
    #     endpoint: @api[:endpoint],
    #     namespace: @api[:namespace],
    #     namespaces: @api[:namespaces],
    #     wsse_auth: [@auth[:user], @auth[:pass]],
    #     element_form_default: :unqualified,
    #     namespace_identifier: :wasp,
    #     env_namespace: :soapenv,
    #     ssl_verify_mode: :none,
    #     logger: Rails.logger,
    #     log_level: :debug,
    #     log: true,
    #     encoding: "UTF-8",
    #     soap_version: 1,
    #     open_timeout: 900,
    #     read_timeout: 900,
    #     raise_errors: false,
    #     pretty_print_xml: true,
    #     strip_namespaces: true
    #   )
    # end

    def qq_config
      qq_conf = TenbewDoiApi::Application.config.QQ_CONFIG[Rails.env]
      {
        :waspTID => qq_conf["waspTID"],
        :serviceID => qq_conf["serviceID"],
        :charge_code => qq_conf["charge_code"],
        :charge_value => qq_conf["charge_value"]
      }
    end

    # def cellc_config
    #   if Rails.env.production?
    #     load_prod_config
    #   else
    #     load_default_config
    #   end
    # end
    def cellc_config
      cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
      {
        :auth => {
          :user => cellc_conf["user"],
          :pass => cellc_conf["pass"]
        },
        :api => {
          :wsdl => cellc_conf["wsdl"] || ENV["DOI_WSDL"],
          :endpoint => cellc_conf["endpoint"] || ENV["DOI_ENDPOINT"],
          :namespace => cellc_conf["namespace"] || ENV["DOI_NAMESPACE"],
          :namespaces => cellc_namespaces
        },
        :web => {
          :url => cellc_conf["url"] || ENV["DOI_URL"],
          :callback_url => cellc_conf["callback_url"] || ENV["DOI_CALLBACK"],
          :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}" || ENV["DOI_HOST"]
        },
        :charge_code => cellc_conf["charge_code"] || ENV["DOI_CHARGE_CODE"]
      }
    end

    def operations
      client.operations
    end

    def cellc_namespaces
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
        {
          "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
          "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
        }
      end
    end

    protected

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
          :url => cellc_conf["url"],
          :callback_url => cellc_conf["callback_url"],
          :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
        },
        :charge_code => cellc_conf["charge_code"]
      }
    end

    def load_default_config
      cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
      if cellc_conf["local_ssh_enabled"] == true
        {
          :auth => {
            :user => "tenbew", :pass => "tenbew678"
          },
          :api => {
            :wsdl => "http://localhost:8081/WaspInterface?wsdl",
            :endpoint => "http://localhost:8081/WaspInterface",
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
          }
        }
      else
        {
          :auth => {
            :user => cellc_conf["user"], :pass => cellc_conf["pass"]
          },
          :api => {
            :wsdl => cellc_conf["wsdl"] || ENV["DOI_WSDL"],
            :endpoint => cellc_conf["endpoint"] || ENV["DOI_ENDPOINT"],
            :namespace => cellc_conf["namespace"] || ENV["DOI_NAMESPACE"],
            :namespaces => {
              "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
              "xmlns:wasp" => "http://wasp.doi.soap.protocol.cellc.co.za"
            }
          },
          :web => {
            :url => cellc_conf["url"] || ENV["DOI_URL"],
            :callback_url => cellc_conf["callback_url"] || ENV["DOI_CALLBACK"],
            :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}" || ENV["DOI_HOST"]
          },
          :charge_code => cellc_conf["charge_code"] || ENV["DOI_CHARGE_CODE"]
        }
      end
    end

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

    # def cellc_config
    #   cellc_conf = TenbewDoiApi::Application.config.CELLC_CONFIG[Rails.env]
    #
    #   if cellc_conf["local_ssh_enabled"] == true
    #     {
    #       :auth => {
    #         :user => cellc_conf["user"],
    #         :pass => cellc_conf["pass"]
    #       },
    #       :api => {
    #         :wsdl => "http://localhost:8081/WaspInterface?wsdl",
    #         :endpoint => "http://localhost:8081/WaspInterface",
    #         :namespace => cellc_conf["namespace"] || doi_namespace,
    #         :namespaces => cellc_namespaces
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
    #         :user => cellc_conf["user"],
    #         :pass => cellc_conf["pass"]
    #       },
    #       :api => {
    #         :wsdl => cellc_conf["wsdl"],
    #         :endpoint => cellc_conf["endpoint"],
    #         :namespace => cellc_conf["namespace"],
    #         :namespaces => cellc_namespaces
    #       },
    #       :web => {
    #         :url => cellc_conf["url"],
    #         :callback_url => cellc_conf["callback_url"],
    #         :host => "#{cellc_conf["ip"]}:#{cellc_conf["port"]}"
    #       },
    #       :charge_code => cellc_conf["charge_code"]
    #     }
    #   end
    # end

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
