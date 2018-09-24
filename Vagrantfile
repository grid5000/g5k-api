# -*- mode: ruby -*-
# vi: set ft=ruby :
#

Vagrant.require_version ">= 1.8.0"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "debian/contrib-jessie64"
  config.vm.hostname = "g5k-local"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest:  13306, host: 13306
  config.vm.network :forwarded_port, guest:  15432, host: 15432
  config.vm.network :forwarded_port, guest:   8000, host:  8000
  config.vm.network :forwarded_port, guest:   8080, host:  8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network :private_network, ip: "192.168.2.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "../reference-repository", "/home/vagrant/reference-repository"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.
  #
  config.vm.provider :virtualbox do |vb|
    #make sure DNS will resolve 
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.memory = 2048
    vb.cpus = 2
  end

  # Ease access to stats.g5kadmin
  config.ssh.forward_agent = true

  #Configure git for within the file
  if File.exists?("#{Dir.home}/.gitconfig")
    config.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
  end
  
  # Provisioning with shell commands on the VM
  config.vm.provision "shell", inline: <<-SHELL
    #!/bin/bash -x
    if ! which pupppet > /dev/null ; then
      sed -i s/httpredir/deb/ /etc/apt/sources.list # faster mirror
      export DEBIAN_FRONTEND=noninteractive
      cd /tmp && wget -q http://apt.puppetlabs.com/puppetlabs-release-pc1-jessie.deb && dpkg -i puppetlabs-release-pc1-jessie.deb
      apt-get update
      apt-get -y install --no-install-recommends puppet-agent
    fi
  SHELL

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file base.pp in the manifests_path directory.
  #
  # An example Puppet manifest to provision the message of the day:
  #
  # # group { "puppet":
  # #   ensure => "present",
  # # }
  # #
  # # File { owner => 0, group => 0, mode => 0644 }
  # #
  # # file { '/etc/motd':
  # #   content => "Welcome to your Vagrant-built virtual machine!
  # #               Managed by Puppet.\n"
  # # }
  #
  config.vm.provision :puppet do |puppet|
    puppet.environment = 'development'
    puppet.environment_path = "puppet"
    puppet.facter = {
      "owner" => ENV['OWNER']||'vagrant',
      "workspace" => ENV['WORKSPACE']||'/vagrant',
      "developer" => ENV['DEVELOPER']||'ajenkins',
      "oardbsite" => ENV['OAR_DB_SITE']||'rennes'
    }
  end

  # config.vm.provision :file, source: (ENV['SSH_KEY'] && "#{ENV['SSH_KEY']}.pub") || "~/.ssh/authorized_keys", destination: "/tmp/toto"
  # config.vm.provision :shell, :inline => "sudo mv /tmp/toto /root/.ssh/authorized_keys"
  # config.vm.provision :shell, :inline => "sudo chown root: /root/.ssh/authorized_keys"
  # config.vm.provision :shell, :inline => "sudo chown root: /root/.ssh/authorized_keys"
  # config.vm.provision :shell, :inline => "if [ $(wc -l .ssh/authorized_keys| cut -d ' ' -f 1) -lt 2 ] ; then sudo cat /root/.ssh/authorized_keys >> /home/vagrant/.ssh/authorized_keys ; fi"

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # config.vm.provision :chef_solo do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { :mysql_password => "foo" }
  # end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision :chef_client do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"
end

