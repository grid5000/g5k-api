require 'yaml'

set :application, "g5k-api"

set :apt, "/var/www/#{application}"
set :puppet, "/tmp/puppet"

set :scm, :git

set :gateway, "crohr@access.rennes.grid5000.fr"
set :user, ENV['REMOTE_USER'] || "root"
set :ssh_options, {
  :port => 22, :keys => ["~/.ssh/id_rsa"], :forward_agent => true
}
set :authorized_keys, "~/.ssh/id_rsa.pub"

set :provisioner, "bundle exec g5k-campaign --site #{ENV['SITE'] || 'rennes'} -a #{authorized_keys} -k #{ssh_options[:keys][0]} -e squeeze-x64-base --name \"#{application}-#{ARGV[0]}\" --no-submit --no-deploy --no-cleanup -w #{ENV['WALLTIME'] || 7200}"

set :pkg_dependencies, %w{libmysqlclient-dev ruby1.9.1-full libxml2-dev libxslt-dev libssl-dev}

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

desc "Package the app as a debian package, on a remote machine."
task :package, :roles => :pkg do
  
  run "date -s \"#{Time.now.to_s}\" && \
        export http_proxy=proxy:3128 && \
        apt-get update && \
        apt-get install #{pkg_dependencies.join(" ")} git-core dh-make dpkg-dev -y && \
        gem1.9.1 install rake bundler --no-ri --no-rdoc && \
        rm -rf /tmp/#{application}*"

  system "mkdir -p pkg/ && git archive HEAD > pkg/#{application}.tar"
  upload("pkg/#{application}.tar", "/tmp/#{application}.tar")
  run "cd /tmp && \
        mkdir -p #{application}/pkg && \
        tar xf #{application}.tar -C #{application} && \
        cd #{application} && \
        export https_proxy=proxy:3128 && \
        export http_proxy=proxy:3128 && \
        PATH=/var/lib/gems/1.9.1/bin:$PATH rake -f lib/tasks/packaging.rake package:debian && \
        cp ../#{application}_*.deb pkg/"

  download "/tmp/#{application}/pkg", "pkg", :once => true, :recursive => true
end

desc "Release the latest package."
task :release, :roles => :apt do
  latest = Dir["pkg/*.deb"].sort.last
  fail "No .deb available in pkg/" if latest.nil?
  latest = File.basename(latest)
  run "mkdir -p #{apt}"
  upload("pkg/#{latest}", "#{apt}/#{latest}")
  run "cd #{apt} && \
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
    "create database #{v['database']}"
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

