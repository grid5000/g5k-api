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

# changed inheritance of class ClustersController - bug 5856
# from ResourcesController to SitesController
# Logic for changing inheritance : From the perspective of a controller,
# the ClustersController is a special case of a SitesController,
# for specific clusters, insofar that this attribute is limited to the status function
class ClustersController < ResourcesController
  # method to return status of a specific cluster - bug 5856
  def status
    result = {
      'uid' => Time.now.to_i,
      'links' => [
        {
          'rel' => 'self',
          'href' => uri_to(status_site_cluster_path(params[:site_id], params[:id])),
          'type' => api_media_type(:g5kitemjson)
        },
        {
          'rel' => 'parent',
          'href' => uri_to(site_cluster_path(params[:site_id], params[:id])),
          'type' => api_media_type(:g5kitemjson)
        }
      ]
    }

    expected_rtypes = ['node']
    expected_rtypes.push('disk') if params[:disks] != 'no'
    result.merge!(OAR::Resource.status(clusters: params[:id], network_address: params[:network_address], job_details: params[:job_details], waiting: params[:waiting], types: expected_rtypes))

    respond_to do |format|
      format.g5kitemjson { render json: result }
      format.json { render json: result }
    end
  end

  protected

  # the parameter passed should be :site_id not :id (cluster)
  def collection_path
    site_clusters_path(params[:site_id])
  end

  # method to prepare links for status of a cluster - bug 5856
  def links_for_item(item)
    links = super(item)

    links.push({
                 'rel' => 'status',
                 'type' => api_media_type(:g5kitemjson),
                 'href' => uri_to(File.join(resource_path(item['uid']), 'status'))
               })
    links
  end
end
