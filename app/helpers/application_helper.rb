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

  def tls_options_for(url, in_or_out = :in)
    Grid5000::Router.tls_options_for(url, in_or_out)
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
    if t
      t.to_s
    end
  end

  def http_request(method, uri, tls_options, timeout = nil, headers = {}, body = nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 5 if timeout

    if tls_options && !tls_options.empty?
      http.cert = tls_options[:cert_chain_file]
      http.key = tls_options[:private_key_file]
      http.verify_mode = tls_options[:verify_peer]
    end

    request = case method
              when :post
                Net::HTTP::Post.new(uri, headers)
              when :get
                Net::HTTP::Get.new(uri, headers)
              when :delete
                Net::HTTP::Delete.new(uri, headers)
              else
                raise "Unknown http method: #{method}"
              end

    request.body = body if body
    http.request(request)
  end
end
