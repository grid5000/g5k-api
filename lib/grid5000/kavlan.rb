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

require 'json'
require 'fileutils'

module Grid5000
  # Class representing vlans
  class Kavlan
    include ApplicationHelper

    attr_accessor :base_uri, :user, :tls_options

    # List all vlans
    def list
      http = call_kavlan(base_uri, :get)
      JSON.parse(http.body)['items']
    end

    # Fetch a specific vlan
    def vlan(id)
      uri = File.join(base_uri, id)
      http = call_kavlan(uri, :get)

      JSON.parse(http.body)
    end

    # Fetch all nodes or a specific one
    def nodes(name = nil)
      uri = if name
              File.join(base_uri, 'nodes', name)
            else
              File.join(base_uri, 'nodes')
            end

      http = call_kavlan(uri, :get)

      JSON.parse(http.body)
    end

    # Fetch nodes for a specific vlan
    def nodes_vlan(id)
      uri = File.join(base_uri, id, 'nodes')
      http = call_kavlan(uri, :get)

      JSON.parse(http.body)['nodes']
    end

    # Fetch one or all users currently using Kavlan
    # When fetching a specific user, a list of assigned vlans is included in
    # response
    def users(id = nil)
      uri = if id
              File.join(base_uri, 'users', id)
            else
              File.join(base_uri, 'users')
            end

      http = call_kavlan(uri, :get)
      JSON.parse(http.body)
    end

    # Fetch users for a vlan
    def vlan_users(id, user_id = nil)
      uri = if user_id
              File.join(base_uri, id, 'users', user_id)
            else
              File.join(base_uri, id, 'users')
            end

      http = call_kavlan(uri, :get)

      if user_id
        if http.code.to_i == 404
          { uid: user_id, status: 'unauthorized' }
        else
          { uid: user_id, status: JSON.parse(http.body)[id] }
        end
      else
        JSON.parse(http.body)
      end
    end

    # Remove rights for a user on a vlan
    def delete_user(id, user_id)
      uri = File.join(base_uri, id, 'users', user_id)
      call_kavlan(uri, :delete)
    end

    # Add rights for a user on a vlan
    def add_user(id, user_id)
      uri = File.join(base_uri, id, 'users', user_id)
      call_kavlan(uri, :put)
    end

    def vlan_exist?(id)
      !list.select! { |item| item['uid'] == id }.empty?
    end

    # Stop or start dhcpd for a vlan
    def dhcpd(id, action)
      uri = File.join(base_uri, id, 'dhcpd')
      call_kavlan_with_data(uri, :put, action)
    end

    # Add nodes to a vlan
    def update_vlan_nodes(id, nodes)
      uri = File.join(base_uri, id)
      call_kavlan_with_data(uri, :post, { nodes: nodes })
    end

    # Return nodes with their associated vlan
    def vlan_for_nodes(nodes)
      uri = File.join(base_uri, 'nodes')
      call_kavlan_with_data(uri, :post, { nodes: nodes })
    end

    private

    def call_kavlan(uri, method)
      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Remote-Ident' => user }
        http_request(method, uri, tls_options, 10, headers)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end

    def call_kavlan_with_data(uri, method, data)
      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'Content-Type' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Remote-Ident' => user }
        http_request(method, uri, tls_options, 10, headers, data.to_json)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end
  end
end
