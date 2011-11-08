#
#  notifications_controller.rb
#  g5k-api
#
#  Created by Cyril Rohr on 2011-10-10.
#  Copyright 2011 Cyril Rohr. All rights reserved.
#

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
    ensure_authenticated!
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
