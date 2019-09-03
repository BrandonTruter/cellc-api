class ApplicationController < ActionController::API
  include ActionController::Serialization

  include DOI
  include Response
  # include Exceptions
end
