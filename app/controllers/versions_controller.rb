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

class VersionsController < ApplicationController
  include Swagger::Blocks

  MAX_AGE = 60.seconds

  swagger_path '/versions' do
    operation :get do
      key :summary, 'List reference-repository versions'
      key :description, 'Fetch a collection of reference-repository git version. '\
        'A version is a Git commit.'
      key :tags, ['version']

      [:branch, :limit, :offset].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Grid'5000's reference-repository commit collection."
        content api_media_type(:g5kcollectionjson)
      end
    end
  end

  swagger_path '/versions/latest' do
    operation :get do
      key :summary, 'Get the latest version of reference-repository'
      key :description, 'Fetch the latest version commit item of reference-repository.'
      key :tags, ['version']

      [:branch].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 307 do
        key :description, "Redirect to latest reference-repository's commit item."
      end
    end
  end

  swagger_path '/versions/{versionId}' do
    operation :get do
      key :summary, 'Get version of reference-repository'
      key :description, 'Fetch a specific version commit item of reference-repository.'
      key :tags, ['version']

      [:versionId, :branch, :limit].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Reference-repository's commit item."
        content api_media_type(:g5kitemjson)
      end

      response 404 do
        key :description, "Reference-repository's commit not found."
        content :'text/plain'
      end
    end
  end

  swagger_path '/sites/{siteId}/versions' do
    operation :get do
      key :summary, "List sites's reference-repository versions"
      key :description, 'Fetch a collection of reference-repository git versions '\
        'for a specific site. A version is a Git commit.'
      key :tags, ['version']

      [:siteId, :branch, :limit].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Grid'5000's reference-repository commit collection."
        content api_media_type(:g5kcollectionjson)
      end
    end
  end

  swagger_path '/sites/{siteId}/versions/latest' do
    operation :get do
      key :summary, "Get the latest version of site's reference-repository"
      key :description, "Fetch the latest site's version commit item of reference-repository."
      key :tags, ['version']

      [:siteId, :branch].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 307 do
        key :description, "Redirect to latest reference-repository's commit item."
      end
    end
  end

  swagger_path '/sites/{siteId}/versions/{versionId}' do
    operation :get do
      key :summary, "Get version of site's reference-repository"
      key :description, 'Fetch a specific version commit item of reference-repository.'
      key :tags, ['version']

      [:siteId, :versionId, :branch, :limit].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Reference-repository's commit item."
        content api_media_type(:g5kitemjson)
      end

      response 404 do
        key :description, "Reference-repository's commit not found."
        content :'text/plain'
      end
    end
  end

  swagger_component do
    parameter :versionId do
      key :name, :versionId
      key :in, :path
      key :description, 'ID of version to fetch, as a Git commit hash.'
      key :required, true
      schema do
        key :type, :string
      end
    end
  end

  def index
    vary_on :accept; allow :get

    branch = params[:branch] || 'master'
    branch = ['origin', branch].join('/') unless Rails.env == 'test'

    versions = repository.versions_for(
      resource_path,
      branch: branch,
      offset: params[:offset],
      limit: params[:limit]
    )

    raise NotFound, "#{resource_path} does not exist." if versions['total'] == 0

    versions['items'].map! do |commit|
      metadata_for_commit(commit, resource_path)
    end
    versions['links'] = [
      {
        'rel' => 'self',
        'href' => uri_to("#{resource_path}/versions"),
        'type' => api_media_type(:g5kcollectionjson)
      },
      {
        'rel' => 'parent',
        'href' => uri_to(resource_path.split('/')[0..-2].join('/').to_s),
        'type' => api_media_type(:g5kitemjson)
      }
    ]

    etag versions.hash
    expires_in MAX_AGE, public: true

    render_result(versions)
  end

  def show
    vary_on :accept; allow :get
    version = params[:id]

    versions = repository.versions_for(
      resource_path,
      branch: version,
      offset: 0,
      limit: 1
    )
    if versions['total'] == 0
      raise NotFound, "The resource '#{resource_path}' does not exist."
    end

    # etag compute_etag(commit.id, resource_uri, response['Content-Type'], options.release_hash)

    output = metadata_for_commit(versions['items'][0], resource_path)

    etag versions.hash
    expires_in MAX_AGE, public: true

    render_result(output)
  end

  def latest
    vary_on :accept; allow :get

    sha = repository.find(resource_path).oid
    render location: request.fullpath.gsub(/latest(.json)?$/, sha), status: 307, plain: ''
  end

  protected

  def resource_path
    @resource_path ||= params[:resource].gsub(%r{/?platforms}, '')
  end

  def metadata_for_commit(commit, resource_path)
    {
      'uid' => commit.oid,
      'date' => commit.time.httpdate,
      'message' => commit.message.chomp,
      'author' => commit.author[:name],
      'type' => 'version',
      'links' => [
        {
          'rel' => 'self',
          'href' => uri_to("#{resource_path}/versions/#{commit.oid}"),
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'parent',
          'href' => uri_to(resource_path),
          'type' => api_media_type(:g5kitemjson)
        }
      ]
    }
  end
end
