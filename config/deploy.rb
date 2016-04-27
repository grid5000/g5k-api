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

require 'yaml'
require File.expand_path("../../lib/grid5000/version", __FILE__)

set :application, ENV['APP_NAME'] || "g5k-api"

set :apt_repo, ENV['REPO_DIR'] || "/var/www/#{application}-devel" 
set :apt_repo, ENV['REPO_DIR'] || "/var/www/#{application}" if ENV['PROD_REPO']
set :puppet, "/tmp/puppet"

set :scm, :git

# abasu (dmargery) : added "unless" block to make package if option GATEWAY='' 
set :gateway, ENV['GATEWAY'] || "#{ENV['USER']}@access.grid5000.fr" unless ENV['NOPROXY']
set :user, ENV['REMOTE_USER'] || "root"

key = ENV['SSH_KEY'] || "~/.ssh/id_rsa"

set :ssh_options, {
  :port => 22, :keys => [key], :forward_agent => true, :keys_only=> true
}
set :authorized_keys, "#{key}.pub"

set :provisioner, "bundle exec g5k-campaign --site #{ENV['SITE'] || 'rennes'} -a #{authorized_keys} -k #{ssh_options[:keys][0]} -e jessie-x64-base --name \"#{application}-#{ARGV[0]}\" --no-submit --no-deploy --no-cleanup -w #{ENV['WALLTIME'] || 7200}"

set :provisioner, "(SSH_KEY=#{key} vagrant up --provision && cat Vagrantfile) | grep private_network | grep -o -E '[0-9][0-9\.]*'" if ENV['USE_VAGRANT']

role :apt, ENV['HOST'] || 'apt.grid5000.fr'
role :app do
  ENV['HOST'] ||= `#{provisioner}`
end
role :dev do
  ENV['HOST'] ||= `#{provisioner}`
end
role :pkg do
  ENV['HOST'] ||= `#{provisioner}`
end


desc "Release the latest package (#{Grid5000::VERSION}). Destination controled by PROD_REPO and REPO_DIR"
task :release, :roles => :apt do
  latest = Dir["pkg/*.deb"].find{|file| file =~ /#{application}_#{Grid5000::VERSION}/}
  fail "No .deb available in pkg/" if latest.nil?
  latest = File.basename(latest)
  run "#{sudo} mkdir -p #{apt_repo}"
  run "#{sudo} chown #{ENV['REMOTE_USER']}:#{ENV['REMOTE_USER']} #{apt_repo}"
  upload("pkg/#{latest}", "#{apt_repo}/#{latest}")
  run "cd #{apt_repo} && \
        #{sudo} apt-get update && \
        #{sudo} apt-get install dpkg-dev -y && \
        #{sudo} dpkg-scanpackages . | gzip -f9 > Packages.gz"
end

desc "Remove the latest package from the APT repository."
task :yank, :roles => :apt do
  latest = Dir["pkg/*.deb"].find{|file| file =~ /#{Grid5000::VERSION}/}
  fail "No .deb available in pkg/" if latest.nil?
  latest = File.basename(latest)
  run "#{sudo} mkdir -p #{apt_repo} && #{sudo} rm \"#{apt_repo}/#{latest}\""
  run "#{sudo} chown #{ENV['REMOTE_USER']}:#{ENV['REMOTE_USER']} #{apt_repo}"
  run "cd #{apt_repo} && \
        #{sudo} apt-get update && \
        #{sudo} apt-get install dpkg-dev -y && \
        #{sudo} dpkg-scanpackages . | gzip -f9 > Packages.gz"
end

desc "Launch a development machine."
task :develop, :roles => :dev do
  run "rm -rf #{puppet}"
  upload "puppet", puppet, :recursive => true, :force => true
  run "apt-get update && \
        apt-get install puppet -y && \
        export http_proxy=proxy:3128 && \
        puppet #{puppet}/development.pp --modulepath #{puppet}/modules/"

  # Hack to create databases, because rake db:create does not work correctly with current version of em-mysql adapter.
  create_dbs = YAML.load_file(
    File.expand_path("../database.yml", __FILE__)
  ).values.map{|v|
    "drop database if exists #{v['database']}; create database #{v['database']}"
  }.join("; ")
  run "mysql -u root -e '#{create_dbs}'"

  remote = roles[:dev].servers[0]
  gateway = connection_factory.gateway_for(remote)
  ports = {3306 => 13306}
  puts "======================================"
  puts "Forwarding SSH ports as follows: #{ports.inspect}."
  {3306 => 13306}.each do |remote_port, local_port|
    port = gateway.open(remote, remote_port, local_port)
  end
  puts "Port forwarding will be cleaned up once you kill this terminal. Please open a new terminal if you want to work on this repo."
  puts "======================================"
  sleep
end

desc "Launch a development machine."
task :install, :roles => :app do
  run "rm -rf #{puppet}"
  upload "puppet", puppet, :recursive => true, :force => true
  run "apt-get update && \
        apt-get install puppet -y && \
        export http_proxy=proxy:3128 && \
        puppet #{puppet}/install.pp --modulepath #{puppet}/modules/"

  remote = roles[:app].servers[0]
  gateway = connection_factory.gateway_for(remote)
  canibalized = "api-server.rennes.grid5000.fr"
  # WARN: this is a bit of a hack, and it can be unsecure to propagate your
  # g5kadmin key (via the SSH agent) on a Grid'5000 node.
  puts "======================================"
  puts "Setting up port forwarding between #{remote}:8888 and #{canibalized}:8888 so that API on #{remote} is able to connect to production api-proxy..."
   puts "If this process hangs, just kill it. The tunnel will still be created."
  cmd = "\
  (ps aux | grep \"ssh -NL 8888:localhost:8888\" | grep -v grep) || \
  (ssh -NL 8888:localhost:8888 g5kadmin@#{canibalized}) \
  "
  puts cmd
  puts gateway.ssh(remote, user, :forward_agent => true).exec!(cmd)
  puts "======================================"
end

