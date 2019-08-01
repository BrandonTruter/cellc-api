class Subscription < ApplicationRecord

  # Assign an API key on create
  before_create do |subscription|
    subscription.api_key = subscription.generate_api_key
  end

  # Generate a unique API key
  def generate_api_key
    loop do
      token = SecureRandom.base64.tr('+/=', 'Qrt')
      break token unless Subscription.exists?(api_key: token)
    end
  end

end
