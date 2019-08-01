class CreateSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :subscriptions do |t|
      t.string :state
      t.string :service
      t.string :msisdn
      t.string :message
      t.string :reference

      t.timestamps
    end
  end
end
