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

module ConfigurationHelper
  def my_config(key)
    Api::Application::CONFIG[key.to_sym] || Api::Application::CONFIG[key.to_s]
  end

  def tmp
    Rails.root.join(my_config(:tmp_path))
  end

  # Returns a string specific to the machine/cluster
  # where this server is hosted
  def whoami
    if Rails.env == "test"
      "rennes"
    else
      ENV['WHOAMI'] || `hostname`.split(".")[1]
    end
  end

end

Rails.extend ConfigurationHelper

Rails.logger.level = Logger.const_get(Rails.my_config(:logger_level) || "INFO")
