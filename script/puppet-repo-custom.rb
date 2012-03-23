# Custom capistrano file
# How to set an SSH gateway :
#    set :gateway, ["pmorillo@access.rennes.grid5000.fr"]

# puppetmgt -a -c api-g5k::server api-server.`hostname  | cut -d"." -f2,2`.grid5000.fr
# puppetmgt -a -c api-g5k::proxy api-proxy.`hostname  | cut -d"." -f2,2`.grid5000.fr

set :user, "g5kadmin"
set :gateway, 'access.grid5000.fr'

# ssh_options[:verbose] = 0

%w{bordeaux grenoble lille lyon luxembourg nancy reims rennes orsay sophia toulouse}.each do |site|
  role :app, "api-server.#{site}.grid5000.fr"
  role :devel, "api-server-devel.#{site}.grid5000.fr"
  role :web, "api-proxy.#{site}.grid5000.fr"
  role :puppet, "puppet.#{site}.grid5000.fr"
  role :sql, "mysql.#{site}.grid5000.fr"
  role :oar, "oar-api.#{site}.grid5000.fr"
end

namespace :api do
  desc "Run puppet on all servers. Use ROLES env variable to choose on which machines you want to run this command."
  task :update, :roles => [:web, :app, :devel, :puppet, :sql] do
    run "#{sudo} aptitude update && #{sudo} puppetd --test"
  end
end
