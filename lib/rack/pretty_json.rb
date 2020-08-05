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

require 'json'

module Rack
  class PrettyJSON
    def initialize(app, options = {})
      @app = app
      @only_if_header = (
        options[:only_if_header] || 'X-Rack-PrettyJSON'
      )
      @only_if_query = (
        options[:only_if_query] || 'pretty'
      )
      @warning = !!options[:warning]
    end

    def call(env)
      client = env['HTTP_' + @only_if_header.gsub(/-/, '_').upcase]

      code, head, body = @app.call(env)

      server = head.delete(@only_if_header) || env['QUERY_STRING']
               .split('&').find { |x| x.split('=')[0] == @only_if_query }

      if head['Content-Type'] && head['Content-Type']
         .split(';')[0] =~ %r{[\+|/]json$}i
        if client || server
          payload = ''
          body.each { |chunk| payload << chunk }
          body = JSON.pretty_generate(
            JSON.load(payload)
          )
          head['Content-Length'] = body.size.to_s
          body = [body]
        elsif @warning
          head['X-Info'] ||= []
          head['X-Info'].push('Use `?pretty=yes` or add the HTTP header `X-Rack-PrettyJSON: yes` if you want pretty output.')
        end
      end

      [code, head, body]
    end
  end
end
