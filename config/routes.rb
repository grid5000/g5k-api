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

  match "/exhibitv2/*rest", :to => redirect {|params| "/ui/javascripts/vendor/exhibitv2/#{params[:rest]}"}
  match '/versions' => 'versions#index', :via => [:get]
  match '/versions/:id' => 'versions#show', :via => [:get]
  match '*resource/versions' => 'versions#index', :via => [:get]
  match '*resource/versions/:id' => 'versions#show', :via => [:get]

  # abasu : 1 line introduced below for correction to bug ref 5065 -- 2015.01.23  
  resources :environments, :only => [:index, :show], :constraints => { :id => /[0-9A-Za-z\-\.]+/ 	}
  resources :network_equipments, :only => [:index, :show]
  resources :sites, :only => [:index, :show] do	
    member do
      get :status
    end
  # abasu : 1 line introduced below for correction to bug ref 5065 -- 2015.01.23  
    resources :environments, :only => [:index, :show], :constraints => { :id => /[0-9A-Za-z\-\.]+/ }
    resources :network_equipments, :only => [:index, :show]
    resources :pdus, :only => [:index, :show]
    resources :clusters, :only => [:index, :show] do
  # abasu : 3 lines introduced below for correction to bug ref 5856 -- 2015.04.17  
      member do
        get :status
      end
      resources :nodes, :only => [:index, :show]
    end
  # abasu bug #7301 to incorporate feature /servers -- 2016.10.24  
    resources :servers, :only => [:index, :show]
    resources :jobs
    resources :deployments
  end
  resources :notifications, :only => [:index, :create]

  match '/ui/events' => redirect('https://www.grid5000.fr/status')

  # Could be simplified once we use Rails >= 3.1 (remove the proc)
  match '/ui' => redirect(proc {|params, request|
    Grid5000::Router.new("/ui/dashboard").call(params, request)
  })
  match '/ui/index' => redirect(proc {|params, request|
    Grid5000::Router.new("/ui/dashboard").call(params, request)
  })
  match '/ui/:page' => 'ui#show', :via => [:get]
  match '/ui/visualizations/:page' => 'ui#visualization', :via => [:get]

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "root#show", :id => "grid5000"

  # See how all your routes lay out with "rake routes"
end
