module Api::V1
  class ApiController < ApplicationController
    include ActionController::HttpAuthentication::Token::ControllerMethods

    # Add a before_action to authenticate all requests.
    # Move this to subclassed controllers if you only
    # want to authenticate certain methods.

    
    # before_action :authenticate

    protected

    # Authenticate request with token based authentication
    def authenticate
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      authenticate_with_http_token do |token, options|
        @current_subscription = Subscription.find_by(api_key: token)
      end
    end

    def render_unauthorized(realm = "Application")
      self.headers["WWW-Authenticate"] = %(Token realm="#{realm}")
      render json: 'Bad credentials', status: :unauthorized
    end

  end
end
