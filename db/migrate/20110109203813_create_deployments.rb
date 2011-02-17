class CreateDeployments < ActiveRecord::Migration
  def self.up
    create_table :deployments, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string    :uid
      t.string    :site_uid
      t.string    :user_uid
      t.string    :environment,   :size => 255
      t.string    :version,       :size => 10 # environment version
      t.string    :status,        :default => "processing"
      t.text      :key
      t.text      :nodes
      t.text      :notifications
      t.text      :result
      t.text      :output
      t.integer   :partition_number, :size => 3
      t.string    :block_device
      t.string    :reformat_tmp
      t.boolean   :disable_disk_partitioning, :default => false
      t.boolean   :disable_bootloader_install, :default => false
      t.boolean   :ignore_nodes_deploying, :default => false
      t.integer   :vlan
      t.integer   :created_at
      t.integer   :updated_at
    end
    
    add_index :deployments, :uid
    add_index :deployments, :environment
    add_index :deployments, :site_uid
    add_index :deployments, :user_uid
    add_index :deployments, :status
    add_index :deployments, :created_at
    add_index :deployments, :updated_at
  end

  def self.down
    drop_table :deployments
  end
end
