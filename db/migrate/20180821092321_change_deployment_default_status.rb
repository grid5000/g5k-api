class ChangeDeploymentDefaultStatus < ActiveRecord::Migration
  def up
    change_column_default(:deployments, :status, 'waiting')
  end

  def down
    change_column_default(:deployments, :status, 'processing')
  end
end
