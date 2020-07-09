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

class RackDebugger
  def initialize(app, logger)
    @app = app
    @logger = logger
  end

  def call(env)
    @logger.info ["  HEAD:", env['REQUEST_METHOD'], env['PATH_INFO'], "-", env.reject{|k,v|
      k !~ /^HTTP\_/ || ["HTTP_X_FORWARDED_HOST", "HTTP_VIA", "HTTP_X_FORWARDED_SERVER", "HTTP_X_FORWARDED_FOR", "HTTP_AUTHORIZATION"].include?(k)
    }.inspect].join(" ")

    if env['rack.input']
      @logger.info ["  BODY:", env['rack.input'].read(10_000).inspect].join(" ")
      env['rack.input'].rewind
    end

    @app.call(env)
  end
end
