# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# abasu - bug #7179 to remove deployments
class RemoveDeployments < ActiveRecord::Migration
  def self.up
    drop_table :deployments
  end

  def self.down
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

end
