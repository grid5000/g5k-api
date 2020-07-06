class RemoveNotificationsFromDeployments < ActiveRecord::Migration[6.0]
  def change
    remove_column :deployments, :notifications, :text
  end
end
