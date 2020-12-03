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

require 'resources_controller'

class NodesController < ResourcesController
  include Swagger::Blocks

  swagger_path '/sites/{siteId}/clusters/{clusterId}/nodes' do
    operation :get do
      key :summary, 'List nodes'
      key :description, "Fetch a collection of Grid'5000 nodes, of a specific cluster."
      key :tags, ['reference-api']

      parameter do
        key :$ref, :deep
      end

      parameter do
        key :$ref, :siteId
      end

      parameter do
        key :$ref, :clusterId
      end

      parameter do
        key :$ref, :branch
      end

      response 200 do
        key :description, "Grid'5000 nodes collection."
        content api_media_type(:g5kcollectionjson)
      end
    end
  end

  swagger_path '/sites/{siteId}/clusters/{clusterId}/nodes/{nodeId}' do
    operation :get do
      key :summary, 'Get node description'
      key :description, 'Fetch the description of a specific node.'
      key :tags, ['reference-api']

      parameter do
        key :$ref, :deep
      end

      parameter do
        key :$ref, :branch
      end

      parameter do
        key :$ref, :siteId
      end

      parameter do
        key :$ref, :clusterId
      end

      parameter do
        key :$ref, :nodeId
      end

      response 200 do
        key :description, "The Grid'5000 node item."
        content api_media_type(:g5kitemjson)
      end

      response 404 do
        key :description, "Grid'5000 node not found."
        content :'text/plain'
      end
    end
  end

  protected

  def collection_path
    site_cluster_nodes_path(params[:site_id], params[:cluster_id])
  end
end
