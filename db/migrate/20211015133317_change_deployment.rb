class ChangeDeployment < ActiveRecord::Migration[6.0]
  def change
    add_column :deployments, :arch, :string
    change_column :deployments, :partition_number, :string
    rename_column :deployments, :partition_number, :partition_label
  end
end
