# Copyright (c) 2009-2024 Inria MC
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

class AccessesController < ApplicationController
  include Swagger::Blocks

  swagger_path '/accesses' do
    operation :get do
      key :summary, 'Get access rules for the platform'
      key :description, "Return access priority for all groups of the platform"
      key :tags, ['accesses']

      [:branch].each do |param|
        parameter do
          key :$ref, param
        end
      end

      response 200 do
        key :description, "Access rules for the platform."
        content api_media_type(:g5kitemjson)
      end
    end
  end


  def all
    all_accesses = repository.find_and_expand(
      '/accesses/all',
      branch: params[:branch] || 'master',
    )

    raise NotFound, "Accesses does not exist." unless all_accesses
    render_result(all_accesses)
  end
end
