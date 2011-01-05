class ApplicationController < ActionController::Base
  include ConfigurationHelper
  
  # before_filter :lookup_credentials, :ensure_authenticated
  
  class ClientError < ActionController::ActionControllerError; end
  class ServerError < ActionController::ActionControllerError; end
  class UnsupportedMediaType < ClientError; end
  class BadRequest < ClientError; end
  class Forbidden < ClientError; end
  class NotFound < ClientError; end
  
  rescue_from UnsupportedMediaType, :with => :unsupported_media_type
  rescue_from BadRequest, :with => :bad_request
  rescue_from Forbidden, :with => :forbidden
  rescue_from NotFound, :with => :not_found
  rescue_from ServerError, :with => :server_error
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found
  
  before_filter :log, :only => [:create, :update]
  
  protected
  def ensure_occi_payload
    supported_content_types = [default_media_type]
    raise UnsupportedMediaType, "Content-Type #{request.media_type.inspect} is not supported. Please try with #{supported_content_types.inspect}" unless supported_content_types.include?(request.media_type)
  end
  
  def lookup_credentials
    invalid_values = ["", "unknown", "(unknown)"]
    cn = request.env["HTTP_#{header_user_cn.gsub("-","_").upcase}"]
    if cn.nil? || invalid_values.include?(cn)
      @credentials = {
        :cn => nil,
        :privileges => []
      }
    else
      @credentials = {
        :cn => cn.downcase,
        :privileges => []
      }
    end
  end
  
  def log
    Rails.logger.debug [:received_headers, request.env]
    Rails.logger.debug [:received_body, request.body.read]
    request.body.rewind
  end
  
  def ensure_authenticated
    @credentials[:cn] || raise(Forbidden)
  end
  
  def authorize!(user_id)
    raise Forbidden if user_id != @credentials[:cn]
  end
  
  def status(http)
    if http.response_header.status == 0
      502 # bad gateway
    else
      http.response_header.status
    end
  end
  
  # ===============
  # = HTTP Errors =
  # ===============
  def unsupported_media_type(exception)
    log_exception(exception)
    render :text => exception.message+"\n", :status => :unsupported_media_type
  end
  
  def bad_request(exception)
    log_exception(exception)
    render :text => exception.message+"\n", :status => :bad_request
  end
  
  def not_found(exception)
    log_exception(exception)
    render :text => exception.message+"\n", :status => :not_found
  end
  
  def server_error(exception)
    log_exception(exception)
    render :text => exception.message+"\n", :status => 500
  end
  
  def forbidden(exception)
    log_exception(exception)
    render :text => "You are not authorized to access this resource\n", :status => :forbidden
  end
  
  def log_exception(exception)
    Rails.logger.debug exception.message
  end
end
