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

# abasu : changed inheritance of class ClustersController - bug ref 5856 -- 2015.3.19
# from ResourcesController to SitesController
# Logic for changing inheritance : From the perspective of a controller,
# the ClustersController is a special case of a SitesController,  
# for specific clusters, insofar that this attribute is limited to the status function
class ClustersController < SitesController

  # abasu : method to return status of a specific cluster - bug ref 5856 -- 2015.3.19
  def status
    result = {
      "uid" => Time.now.to_i,
      "nodes" => OAR::Resource.status(:clusters => params[:id]),
      "links" => [
        {
          "rel" => "self",
          "href" => uri_to(status_site_path(params[:id])),
          "type" => media_type(:g5kitemjson)
        },
        {
          "rel" => "parent",
          "href" => uri_to(site_path(params[:id])),
          "type" => media_type(:g5kitemjson)
        }
      ]
    }

    respond_to do |format|
      format.g5kitemjson { render :json => result }
      format.json { render :json => result }
    end
  end

  protected
  
  def collection_path
    site_clusters_path(params[:site_id])
  end

end
