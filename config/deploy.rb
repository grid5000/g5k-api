set :application, "g5k-api"

set :apt, "/var/www/#{application}"
set :puppet, "/tmp/puppet"

set :scm, :git

set :gateway, "crohr@access.lille.grid5000.fr"
set :user, "root"
set :ssh_options, {
  :port => 22, :keys => ["~/.ssh/id_rsa"]
}
set :authorized_keys, "~/.ssh/id_rsa.pub"

set :provisioner, "bundle exec g5k-campaign --site #{ENV['SITE'] || 'rennes'} -a #{authorized_keys} -k #{ssh_options[:keys][0]} -e squeeze-x64-base --no-cleanup -w #{ENV['WALLTIME'] || 7200}"

set :pkg_dependencies, %w{libmysqlclient-dev ruby1.9.1-full}

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
  run "export http_proxy=proxy:3128 && \
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
        apt-get update && \
        apt-get install dpkg-dev -y && \
        dpkg-scanpackages . | gzip -f9 > Packages.gz"
end

desc "Launch a development machine."
task :develop, :roles => :dev do
  run "rm -rf #{puppet}"
  upload "puppet", puppet, :recursive => true, :force => true
  run "apt-get update && \
        apt-get install puppet -y && \
        export http_proxy=proxy:3128 && \
        puppet #{puppet}/development.pp --modulepath #{puppet}/modules/"

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

