class SubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :state, :service, :msisdn, :message, :reference # , :api_key

end
