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

require 'grid5000/router'

Api::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  get '/versions' => 'versions#index'
  get '/versions/:id' => 'versions#show'
  get '*resource/versions' => 'versions#index'
  get '*resource/versions/:id' => 'versions#show'

  resources :network_equipments, only: %i[index show]
  resources :sites, only: %i[index show] do
    get '/vlans/users' => 'vlans_users_all#index'
    get '/vlans/users/:user_id' => 'vlans_users_all#show'

    resources :vlans, only: %i[index show] do
      member do
        put 'dhcpd' => 'vlans#dhcpd'
        match 'dhcpd' => 'errors#err_method_not_allowed', :via => [:all]
      end

      resources :vlans_users, path: '/users', only: %i[index show destroy] do
        member do
          put '/' => 'vlans_users#add'
        end
      end
    end

    member do
      get :status
    end

    resources :network_equipments, only: %i[index show]
    resources :pdus, only: %i[index show]

    resources :clusters, only: %i[index show] do
      member do
        get :status
      end
      resources :nodes, only: %i[index show]
    end

    resources :servers, only: %i[index show]
    resources :jobs
    resources :deployments
  end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root to: 'root#show', id: 'grid5000'

  # See how all your routes lay out with "rake routes"
end
