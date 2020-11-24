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
  MAX_AGE = 60.seconds

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

    respond_to do |format|
      format.g5kcollectionjson { render json: versions }
      format.json { render json: versions }
    end
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

    respond_to do |format|
      format.g5kitemjson { render json: output }
      format.json { render json: output }
    end
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
