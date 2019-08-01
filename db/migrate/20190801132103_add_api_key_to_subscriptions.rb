class AddApiKeyToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriptions, :api_key, :string
    add_column :subscriptions, :doi_key, :string
  end
end
