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

require 'swagger'
require 'grid5000/oar_api'
require 'grid5000/kavlan'

class ApplicationController < ActionController::API
  include ::ActionController::MimeResponds
  include ApplicationHelper

  before_action :lookup_credentials

  # additional classes introduced to handle all possible exceptions
  # as per status codes https://api.grid5000.fr/doc/stable/reference/spec.html
  # class & subclasses to handle client-side exceptions (Error codes 4xx)
  class ClientError < ActionController::ActionControllerError; end
  class BadRequest < ClientError; end             # Error code 400
  class AuthorizationRequired < ClientError; end  # Error code 401
  class Forbidden < ClientError; end              # Error code 403
  class NotFound < ClientError; end               # Error code 404
  class MethodNotAllowed < ClientError; end       # Error code 405
  class NotAcceptable < ClientError; end          # Error code 406
  class PreconditionFailed < ClientError; end     # Error code 412
  class UnprocessableEntity < ClientError; end    # Error code 422

  # class & subclasses to handle server-side exceptions (Error codes 5xx)
  class ServerError < ActionController::ActionControllerError; end
  class UnsupportedMediaType < ClientError        # Error code 415 (moved to server-side)
    def initialize(content_type)
      super("Content-Type '#{content_type}' is not supported")
    end
  end
  class BadGateway < ServerError; end             # Error code 50x (to be refined later)
  class ServerUnavailable < ServerError; end      # Error code 503

  # This thing must alway come first, or it will override other rescue_from.
  rescue_from Exception, with: :server_error

  # exception-handlers for client-side exceptions
  rescue_from BadRequest, with: :bad_request                        # for 400
  rescue_from AuthorizationRequired, with: :authorization_required  # for 401
  rescue_from Forbidden, with: :forbidden                           # for 403
  rescue_from NotFound, with: :not_found                            # for 404
  rescue_from ActiveRecord::RecordNotFound, with: :not_found        # for 404
  rescue_from MethodNotAllowed, with: :method_not_allowed           # for 405
  rescue_from NotAcceptable, with: :not_acceptable                  # for 406
  rescue_from PreconditionFailed, with: :precondition_failed        # for 412
  rescue_from UnsupportedMediaType, with: :unsupported_media_type   # for 415
  rescue_from UnprocessableEntity, with: :unprocessable_entity      # for 422

  # exception-handlers for client-side exceptions
  rescue_from ServerError, with: :server_error                      # for 500
  rescue_from BadGateway, with: :bad_gateway                        # for 502
  rescue_from ServerUnavailable, with: :server_unavailable          # for 503

  # exception-handlers for custom repository errors
  rescue_from Grid5000::Errors::Repository::BranchNotFound, with: :not_found
  rescue_from Grid5000::Errors::Repository::CommitNotFound, with: :not_found
  rescue_from Grid5000::Errors::Repository::RefNotFound, with: :not_found

  # exception-handlers for custom oarapi errors
  rescue_from Grid5000::Errors::OarApi::NotFound, with: :not_found
  rescue_from Grid5000::Errors::OarApi::Forbidden, with: :forbidden
  rescue_from Grid5000::Errors::OarApi::BadRequest, with: :bad_request

  # exception-handlers for custom kavlanapi errors
  rescue_from Grid5000::Errors::Kavlan::UnknownNode, with: :not_found
  rescue_from Grid5000::Errors::Kavlan::Forbidden, with: :forbidden

  protected

  def render_result(content, render_opts = {})
    object = render_opts.merge(json: content)
    respond_to do |format|
      if object[:json].is_a?(Hash) && object[:json].has_key?('items')
        format.g5kcollectionjson { render object }
      else
        format.g5kitemjson { render object }
      end
      format.any do
        render object.merge(content_type: 'application/json')
      end
    end
  end

  def lookup_credentials
    invalid_values = ['', 'unknown', '(unknown)']
    cn = request.env["HTTP_#{Rails.my_config(:header_user_cn).gsub('-', '_').upcase}"] ||
         ENV["HTTP_#{Rails.my_config(:header_user_cn).gsub('-', '_').upcase}"]
    @credentials = if cn.nil? || invalid_values.include?(cn)
                     {
                       cn: nil,
                       privileges: []
                     }
                   else
                     {
                       cn: cn.downcase,
                       privileges: []
                     }
                   end
  end

  def is_anonymous?
    @credentials[:cn] == 'anonymous'
  end

  def ensure_authenticated!
    (@credentials[:cn] && @credentials[:cn] != 'anonymous') || raise(Forbidden)
  end

  def authorize!(user_id)
    raise Forbidden if user_id != @credentials[:cn]
  end

  def render_error(exception, options = {})
    log_exception(exception)
    message = options[:message] || exception.message
    render  plain: message,
            status: options[:status]
  end

  def log_exception(exception)
    Rails.logger.warn exception.message
    Rails.logger.debug exception.backtrace.join(';')
  end

  # ===============
  # = HTTP Errors =
  # ===============
  # Most of the new methods added are just stubs for introduced for
  # the sake of completeness  of HTTP error codes handling.
  # If such error conditions become prominent in the the future,
  # they should be overloaded in subclasses.
  def bad_request(exception)
    opts = { status: 400 }
    opts[:message] = 'Bad Request' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def authorization_required(exception)
    opts = { status: 401 }
    opts[:message] = 'Authorization Required' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def forbidden(exception)
    opts = { status: 403 }
    opts[:message] = 'You are not authorized to access this resource' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def not_found(exception)
    opts = { status: 404 }
    opts[:message] = 'Not Found' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def method_not_allowed(exception)
    opts = { status: 405 }
    opts[:message] = 'Method Not Allowed' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def not_acceptable(exception)
    opts = { status: 406 }
    opts[:message] = 'Not Acceptable' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def precondition_failed(exception)
    opts = { status: 412 }
    opts[:message] = 'Precondition Failed' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def unsupported_media_type(exception)
    opts = { status: 415 }
    opts[:message] = 'Unsupported Media Type' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def unprocessable_entity(exception)
    opts = { status: 422 }
    opts[:message] = 'Unprocessable Entity' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def server_error(exception)
    opts = { status: 500 }
    opts[:message] = 'Internal Server Error' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def bad_gateway(exception)
    opts = { status: 502 }
    opts[:message] = 'Bad Gateway' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def server_unavailable(exception)
    opts = { status: 503 }
    opts[:message] = 'Server Unavailable' if exception.message == exception.class.name
    render_error(exception, opts)
  end

  # ================
  # = HTTP Headers =
  # ================
  def allow(*args)
    response.headers['Allow'] = args.flatten.map { |m| m.to_s.upcase }.join(',')
  end

  def vary_on(*args)
    response.headers['Vary'] ||= ''
    response.headers['Vary'] = [
      response.headers['Vary'].split(','),
      args
    ].flatten.join(',')
  end

  def etag(*args)
    response.etag = args.join('.')
  end

  def last_modified(time)
    response.last_modified = time.utc
  end
end
