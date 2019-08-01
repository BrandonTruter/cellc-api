class SubscriptionSerializer < ActiveModel::Serializer
  attributes :id, :state, :service, :msisdn, :message, :reference

end
