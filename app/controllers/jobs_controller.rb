class JobsController < ApplicationController
  
  def index
    # hit OAR DB
    Job.each
  end
  
  def show
    # hit OAR DB
  end
  
  def destroy
    # forward to OAR API
  end
  
  def create
    # forward to OAR API
  end
  
end
