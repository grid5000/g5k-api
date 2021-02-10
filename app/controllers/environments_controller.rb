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
#

require 'grid5000/environments'

class EnvironmentsController < ApplicationController
  include Swagger::Blocks

  before_action :load_kadeploy_environments, :forbid_anonymous_user_param

  swagger_path "/sites/{siteId}/environments" do
    operation :get do
      key :summary, 'List environments'
      key :description, "Fetch the list of all the public and authenticated user's "\
        "environments for site."
      key :tags, ['deployment']

      [:siteId, :latest_only, :user, :arch, :name].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kcollectionjson) do
          schema do
            key :'$ref', :EnvironmentCollection
          end
        end

        key :description, 'Environment collection for site.'
      end
    end
  end

  swagger_component do
    parameter :latest_only do
      key :name, :latest_only
      key :in, :query
      key :description, 'Fetch description of all environments versions, instead ' \
        'of the latest only.'
      schema do
        key :type, :string
        key :default, 'yes'
        key :example, 'no'
        key :pattern, '^(yes|no)$'
      end
    end

    parameter :user do
      key :name, :user
      key :in, :query
      key :description, 'Fetch environments owned by the specified user.'
      schema do
        key :type, :string
        key :example, 'auser'
      end
    end

    parameter :name do
      key :name, :name
      key :in, :query
      key :description, 'Fetch environments with the specified name.'
      schema do
        key :type, :string
        key :example, 'centos7-ppc64-min'
      end
    end

    parameter :arch do
      key :name, :arch
      key :in, :query
      key :description, 'Fetch environments for a specific CPU architecture.'
      schema do
        key :type, :string
        key :example, 'ppc64'
      end
    end
  end

  # List environments
  def index
    allow :get

    items = @environments.list(params)

    items.each do |item|
      item['links'] ||= links_for_item(item)
    end

    result = {
      'total' => items.length,
      'offset' => 0,
      'items' => items,
      'links' => links_for_collection
    }

    render_result(result)
  end

  swagger_path "/sites/{siteId}/environments/{environmentId}" do
    operation :get do
      key :summary, 'Get environment'
      key :description, 'Fetch a specific environment.'
      key :tags, ['deployment']

      [:siteId, :environmentId].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        content api_media_type(:g5kitemjson) do
          schema do
            key :'$ref', :Environment
          end
        end

        key :description, 'The environment item.'
      end

      response 404 do
        content :'text/plain'
        key :description, 'Environment not found.'
      end
    end
  end

  # Display the details of an environment
  def show
    allow :get
    expires_in 60.seconds

    items = @environments.find(params[:id], params)
    if items.empty?
      raise NotFound, "Cannot find environment #{params[:id]}"
    end

    # There should be only one result for a uid (name + submission date)
    item = items.first
    item['links'] ||= links_for_item(item)

    render_result(item)
  end

  protected

  def collection_path
    site_environments_path(params[:site_id])
  end

  def parent_path
    site_path(params[:site_id])
  end

  def resource_path(id)
    File.join(collection_path, id.to_s)
  end

  def links_for_item(item)
    [
      {
        'rel' => 'self',
        'href' => uri_to(resource_path(item['uid'])),
        'type' => api_media_type(:g5kitemjson)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(collection_path),
        'type' => api_media_type(:g5kcollectionjson)
      }
    ]
  end

  def links_for_collection
    [
      {
        'rel' => 'self',
        'href' => uri_to(collection_path),
        'type' => api_media_type(:g5kcollectionjson)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(parent_path),
        'type' => api_media_type(:g5kitemjson)
      }
    ]
  end

  def api_path
    uri_to(
      File.join(
        site_path(params[:site_id]),
        '/internal/kadeployapi/environments'
      ),
      :out
    )
  end

  def load_kadeploy_environments
    @environments = Grid5000::Environments.new
    @environments.tls_options = tls_options_for(:out)
    @environments.base_uri = api_path
    @environments.user = @credentials[:cn]
  end

  # If anonymous and asking for users' environments, we throw a 403
  def forbid_anonymous_user_param
    if is_anonymous? && params.has_key?('user')
      raise Forbidden, 'Not allowed to list other users environments, because '\
        'you are seen as an anonymous one'
    end
  end
end
