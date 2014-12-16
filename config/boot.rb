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

require 'rubygems'

require 'yaml'
YAML::ENGINE.yamler = "syck"

# Attempts to use a vendored Bundler, if any
vendored_gems = File.expand_path(
  '../../vendor/bundle/ruby/1.9.1/gems', __FILE__
)

vendored_bundler = Dir["#{vendored_gems}/bundler-*/lib"].sort.last

if !vendored_bundler.nil? && !$LOAD_PATH.include?(vendored_bundler)
  $LOAD_PATH.unshift(vendored_bundler)
end

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)
