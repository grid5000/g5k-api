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
    include Swagger::Blocks

    attr_accessor :base_uri, :user, :tls_options

    # Swagger doc
    swagger_component do
      parameter :vlanId do
        key :name, :vlanId
        key :in, :path
        key :description, 'ID of vlan to fetch.'
        key :required, true
        schema do
          key :type, :integer
        end
      end

      parameter :userId do
        key :name, :userId
        key :in, :path
        key :description, "ID of Grid'5000 user."
        key :required, true
        schema do
          key :type, :string
        end
      end

      schema :Vlan do
        key :required, [:uid, :type, :links]

        property :uid do
          key :type, :integer
          key :description, 'The Vlan ID.'
          key :example, 2
        end

        property :type do
          key :type, :string
          key :description, 'The Vlan type (kavlan, kavlan-global, kavlan-global, '\
            'kavlan-global-remote).'
          key :example, 'kavlan-local'
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
              'rel': 'dhcpd',
              'type': 'application/vnd.grid5000.item+json',
              'href': '/3.0/sites/grenoble/vlans/21/dhcpd'
            },
            {
              'rel': 'nodes',
              'type': 'application/vnd.grid5000.item+json',
              'href': '/3.0/sites/grenoble/vlans/21/nodes'
            },
            {
              'rel': 'users',
              'type': 'application/vnd.grid5000.collection+json',
              'href': '/3.0/sites/grenoble/vlans/21/users'
            },
            {
              'rel': 'self',
              'href': '/3.0/sites/grenoble/vlans/21',
              'type': 'application/vnd.grid5000.item+json'
            },
            {
              'rel': 'parent',
              'href': '/3.0/sites/grenoble/vlans',
              'type': 'application/vnd.grid5000.collection+json'
            }]
        end
      end

      schema :VlanItems do
        key :required, [:items]
        property :items do
          key :type, :array
          items do
            key :'$ref', :Vlan
          end
        end
      end

      schema :VlanCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :'$ref', :VlanItems
          end
          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel': 'nodes',
                  'href': '/sid/sites/grenoble/vlans/nodes',
                  'type': 'application/vnd.grid5000.collection+json'
                },
                {
                  'rel': 'users',
                  'href': '/sid/sites/grenoble/vlans/users',
                  'type': 'application/vnd.grid5000.collection+json'
                },
                {
                  'rel': 'self',
                  'href': '/sid/sites/grenoble/vlans',
                  'type': 'application/vnd.grid5000.collection+json'
                },
                {
                  'rel': 'parent',
                  'href': '/sid/sites/grenoble',
                  'type': 'application/vnd.grid5000.item+json'
                }]
            end
          end
        end
      end

      schema :VlanUserAllCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :required, [:items]
            property :items do
              key :type, :array
              items do
                key :'$ref', :VlanUserAll
              end
            end
          end

          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel':'self',
                  'href':'/3.0/sites/grenoble/vlans/users',
                  'type':'application/vnd.grid5000.collection+json'
                },
                {
                  'rel':'parent',
                  'href':'/3.0/sites/grenoble/vlans',
                  'type':'application/vnd.grid5000.collection+json'
                }]
            end
          end
        end
      end

      schema :VlanUserCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :required, [:items]
            property :items do
              key :type, :array
              items do
                key :'$ref', :VlanUser
              end
            end
          end

          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel':'self',
                  'href':'/3.0/sites/grenoble/4/vlans/users',
                  'type':'application/vnd.grid5000.collection+json'
                },
                {
                  'rel':'parent',
                  'href':'/3.0/sites/grenoble/4/vlans',
                  'type':'application/vnd.grid5000.collection+json'
                }]
            end
          end
        end
      end

      schema :VlanUser do
        property :uid do
          key :type, :string
          key :description, "A Grid'5000 user id."
          key :example, 'auser'
        end

        property :status do
          key :type, :string
          key :description, "Status of user for a vlan, 'authorized' or "\
            "'unauthorized'."
          key :example, 'authorized'
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
            'rel':'self',
            'href':'/3.0/sites/grenoble/vlans/4/users/auser',
            'type':'application/vnd.grid5000.item+json'
          },
          {
            'rel':'parent',
            'href':'/3.0/sites/grenoble/vlans/4/users',
            'type':'application/vnd.grid5000.collection+json'
          }]
        end
      end

      schema :VlanUserAll do
        property :uid do
          key :type, :string
          key :description, "A Grid'5000 user id."
          key :example, 'auser'
        end

        property :vlans do
          key :type, :array
          key :description, 'Vlan id on which user has rights.'
          items do
            key :type, :integer
          end
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
            'rel':'self',
            'href':'/3.0/sites/grenoble/vlans/users/auser',
            'type':'application/vnd.grid5000.item+json'
          },
          {
            'rel':'parent',
            'href':'/3.0/sites/grenoble/vlans/users',
            'type':'application/vnd.grid5000.collection+json'
          }]
        end
      end

      schema :VlanNode do
        property :uid do
          key :type, :string
          key :format, :hostname
          key :description, "A Grid'5000 node address."
          key :example, 'dahu-3.grenoble.grid5000.fr'
        end

        property :vlan do
          key :type, :integer
          key :description, "The vlan id."
          key :example, '4'
        end

        property :links do
          key :type, :array
          items do
            key :'$ref', :Links
          end
          key :example, [{
            'rel':'self',
            'href':'/3.0/sites/grenoble/vlans/nodes/dahu-3.grenoble.grid5000.fr',
            'type':'application/vnd.grid5000.item+json'
          },
          {
            'rel':'parent',
            'href':'/3.0/sites/grenoble/vlans/nodes',
            'type':'application/vnd.grid5000.collection+json'
          }]
        end
      end

      schema :VlanNodeCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :required, [:items]
            property :items do
              key :type, :array
              items do
                key :'$ref', :VlanNode
              end
            end
          end

          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel':'self',
                  'href':'/3.0/sites/grenoble/4/nodes',
                  'type':'application/vnd.grid5000.collection+json'
                },
                {
                  'rel':'parent',
                  'href':'/3.0/sites/grenoble/4',
                  'type':'application/vnd.grid5000.item+json'
                }]
            end
          end
        end
      end

      schema :VlanAllNodeCollection do
        allOf do
          schema do
            key :'$ref', :BaseApiCollection
          end

          schema do
            key :required, [:items]
            property :items do
              key :type, :array
              items do
                key :'$ref', :VlanNode
              end
            end
          end

          schema do
            property :links do
              key :type, :array
              items do
                key :'$ref', :Links
              end
              key :example, [{
                  'rel':'self',
                  'href':'/3.0/sites/grenoble/nodes',
                  'type':'application/vnd.grid5000.collection+json'
                },
                {
                  'rel':'parent',
                  'href':'/3.0/sites/grenoble',
                  'type':'application/vnd.grid5000.item+json'
                }]
            end
          end
        end
      end

      #TODO: fix schema
      schema :VlanAddResponse do
        key :type, :object
        property :node_address do
          key :type, :object
          property :status do
            key :type, :string
            key :description, "The status for node addition to vlan, can be 'success' "\
              "'failure' or 'unchanged'."
          end

          property :message do
            key :type, :string
            key :description, 'A message about the node addition status.'
          end
        end
      end
    end

    # List all vlans
    def list
      http = call_kavlan(base_uri, :get)
      continue_if!(http, is: [200])

      JSON.parse(http.body)['items']
    end

    # Fetch a specific vlan
    def vlan(id)
      uri = File.join(base_uri, id)
      http = call_kavlan(uri, :get)
      continue_if!(http, is: [200])

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
      continue_if!(http, is: [200])
      result = JSON.parse(http.body)

      if result.first[1] == 'unknown'
        raise Errors::Kavlan::UnknownNode, result.first[0]
      else
        result
      end
    end

    # Fetch nodes for a specific vlan
    def nodes_vlan(id)
      uri = File.join(base_uri, id, 'nodes')
      http = call_kavlan(uri, :get)
      continue_if!(http, is: [200])

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
      continue_if!(http, is: [200])

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
      continue_if!(http, is: [200, 404])

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
      http = call_kavlan(uri, :delete)
      continue_if!(http, is: [204, 403])

      if http.code.to_i == 403
        raise Errors::Kavlan::Forbidden
      end
    end

    # Add rights for a user on a vlan
    # NOTE: not working, need to look at kavlan source code to find the correct
    #       request
    def add_user(id, user_id)
      uri = File.join(base_uri, id, 'users', user_id)
      http = call_kavlan(uri, :put)
      continue_if!(http, is: [200, 201, 202, 203, 204, 403])

      if http.code.to_i == 403
        raise Errors::Kavlan::Forbidden
      end
    end

    def vlan_exist?(id)
      !list.select! { |item| item['uid'] == id }.empty?
    end

    # Stop or start dhcpd for a vlan
    def dhcpd(id, action)
      uri = File.join(base_uri, id, 'dhcpd')
      http = call_kavlan_with_data(uri, :put, action)
      continue_if!(http, is: [204, 403])

      if http.code.to_i == 403
        raise Errors::Kavlan::Forbidden
      end
    end

    # Add nodes to a vlan
    def update_vlan_nodes(id, nodes)
      uri = File.join(base_uri, id)
      http = call_kavlan_with_data(uri, :post, { nodes: nodes })
      continue_if!(http, is: [200, 403])

      if http.code.to_i == 403
        raise Errors::Kavlan::Forbidden
      end

      http.body
    end

    # Return nodes with their associated vlan
    def vlan_for_nodes(nodes)
      uri = File.join(base_uri, 'nodes')
      http = call_kavlan_with_data(uri, :post, { nodes: nodes })
      continue_if!(http, is: [200, 403])

      if http.code.to_i == 403
        raise Errors::Kavlan::Forbidden
      end

      http.body
    end

    private

    def call_kavlan(uri, method)
      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Api-User-Cn' => user }
        http_request(method, uri, tls_options, 10, headers)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end

    def call_kavlan_with_data(uri, method, data)
      begin
        headers = { 'Accept' => Mime::Type.lookup_by_extension(:json).to_s,
                    'Content-Type' => Mime::Type.lookup_by_extension(:json).to_s,
                    'X-Api-User-Cn' => user }
        http_request(method, uri, tls_options, 10, headers, data.to_json)
      rescue StandardError
        raise "Unable to contact #{uri}"
      end
    end
  end

  module Errors
    module Kavlan
      class UnknownNode < StandardError
        def initialize(node)
          super("Unknown node '#{node}'.")
        end
      end

      class Forbidden < StandardError
        def initialize
          super('Not enough privileges on Kavlan resources')
        end
      end
    end
  end
end
