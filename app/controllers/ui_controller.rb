class UiController < ApplicationController
  
  def show
    params[:page] ||= "dashboard"
    @id = params[:page].downcase.gsub(/[^a-z]/,'_').squeeze('_')
    @title = params[:page]
    
    respond_to do |format|
      format.html {
        render params[:page].to_sym
      }
    end
  end
  
  def visualization

    @id = params[:page].downcase.gsub(/[^a-z]/,'_').squeeze('_')
    @title = params[:page]
    
    respond_to do |format|
      format.html {
        render "ui/visualizations/#{params[:page]}.html.haml"
      }
    end
  end
end