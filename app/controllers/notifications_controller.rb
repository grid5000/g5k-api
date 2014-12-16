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
#  notifications_controller.rb
#  g5k-api
#
#  Created by Cyril Rohr on 2011-10-10.

class NotificationsController < ApplicationController

  # Placeholder to be Restfully-compliant.
  # Always returns an empty list.
  def index
    allow :get, :post;
    result = {
      :items => [],
      :total => 0,
      :links => [
        {
          :rel => "parent",
          :href => uri_to(root_path)
        },
        {
          :rel => "self",
          :href => uri_to(notifications_path)
        }
      ]
    }
    respond_to do |format|
      format.g5kcollectionjson { render :json => result }
      format.json { render :json => result }
    end
  end

  # deliver a notification
  def create
    @notification = Notification.new(params)
    if @notification.valid?
      EM.add_timer(0) {
        Fiber.new{ @notification.deliver }.resume
      }
      head    :accepted
    else
      render  :status => :bad_request,
              :text => "Your notification is invalid: #{@notification.errors.join("; ")}."
    end
  end

end
