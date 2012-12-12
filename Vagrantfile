# -*- mode: ruby -*-
# vi: set ft=ruby :
#

Vagrant::Config.run do |config|

  config.vm.define :api do |api|
    api.vm.box = 'debian-squeeze-x64-puppet_3.0.1'
    api.vm.box_url = 'https://vagrant.irisa.fr/boxes/debian-squeeze-x64-puppet_3.0.1.box'
    api.vm.forward_port 3306, 13306
    api.vm.network :hostonly, "192.168.2.10"
    api.vm.share_folder "puppet_modules", "/srv/puppet/modules", "puppet/modules"
    api.vm.provision :puppet, :pp_path => "/srv/puppet/vagrant", :options =>  ["--modulepath", "/srv/puppet/modules"] do |puppet|
      puppet.manifests_path = "puppet"
      puppet.manifest_file = "development.pp"
    end
  end

end
