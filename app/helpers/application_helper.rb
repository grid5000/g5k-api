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

require 'grid5000/repository'
require 'grid5000/router'

module ApplicationHelper
  def link_attributes_for(attributes = {})
    attributes[:type] ||= default_media_type
    attributes
  end

  def uri_to(path, in_or_out = :in, relative_or_absolute = :relative)
    Grid5000::Router.uri_to(request, path, in_or_out, relative_or_absolute)
  end

  def tls_options_for(in_or_out = :in)
    Grid5000::Router.tls_options_for(in_or_out)
  end

  def http_request(method, uri, tls_options, timeout = nil, headers = {}, body = nil)
    Grid5000::Router.http_request(method, uri, tls_options, timeout, headers, body)
  end

  def api_version
    Grid5000::Router.api_version(request)
  end

  # Analyses the response status of the given HTTP response.
  #
  # Raise BadGateway if status is 0.
  # Raise ServerError if status is not in the expected status codes in options[:is] .
  def continue_if!(http, options = {})
    # Allow the list of "non-error" http codes
    allowed_status = [options[:is] || (200..299).to_a].flatten

    status = http.code.to_i

    # HACK: to make rspec tests working, indeed for a unknown reason, http.uri is
    # nil when running the specs suite
    http.uri = http.header['Location'] if http.uri.nil?

    if status.between?(400, 599) # error status
      # http.method always returns nil. Bug?
      # msg = "#{http.method} #{http.uri} failed with status #{status}"
      msg = "Request to #{http.uri} failed with status #{status}: #{http.body}"
      Rails.logger.error msg
    end

    case status
    when *allowed_status   # Status codes (200, ..., 299)
      true
    when 400
      raise ApplicationController::BadRequest, msg
    when 401
      raise ApplicationController::AuthorizationRequired, msg
    when 403
      raise ApplicationController::Forbidden, msg
    when 404
      raise ApplicationController::NotFound, msg
    when 405
      raise ApplicationController::MethodNotAllowed, msg
    when 406
      raise ApplicationController::NotAcceptable, msg
    when 412
      raise ApplicationController::PreconditionFailed, msg
    when 415
      raise ApplicationController::UnsupportedMediaType, msg
    when 502
      raise ApplicationController::BadGateway, msg
    when 503
      raise ApplicationController::ServerUnavailable, msg
    else
      raise ApplicationController::ServerError, "Request to #{http.uri} failed with status #{status}: #{http.body}"
    end

    case status
    when *allowed_status   # Status codes (200, ..., 299)
      true
    when 400
      raise ApplicationController::BadRequest, msg
    when 401
      raise ApplicationController::AuthorizationRequired, msg
    when 403
      raise ApplicationController::Forbidden, msg
    when 404
      raise ApplicationController::NotFound, msg
    when 405
      raise ApplicationController::MethodNotAllowed, msg
    when 406
      raise ApplicationController::NotAcceptable, msg
    when 412
      raise ApplicationController::PreconditionFailed, msg
    when 415
      raise ApplicationController::UnsupportedMediaType, msg
    when 502
      raise ApplicationController::BadGateway, msg
    when 503
      raise ApplicationController::ServerUnavailable, msg
    else
      raise ApplicationController::ServerError, "Request to #{http.uri} failed with unexpected status #{status}: #{http.body} ; could be a TLS problem"
    end
  end

  def repository
    @repository ||= Grid5000::Repository.new(
      File.expand_path(
        Rails.my_config(:reference_repository_path),
        Rails.root
      ),
      Rails.my_config(:reference_repository_path_prefix),
      Rails.logger
    )
  end

  def api_media_type(type)
    t = Mime::Type.lookup_by_extension(type)
    t&.to_s
  end
end
