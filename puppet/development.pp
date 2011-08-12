# This puppet manifest is just here to configure a vanilla squeeze with the
# required libs and configuration to serve as a development machine for the
# g5k-api software. Production recipes are in the Grid'5000 puppet repository.
class manifest {
  Package {
    require => Exec["sources update"]
  }

  exec { "sources update":
      command => "apt-get update",
      path => "/usr/bin:/usr/sbin:/bin",
      refreshonly => true;
  }

  package{"ruby1.9.1-full":
    ensure => latest
  }

  package{"git-core":
    ensure => latest
  }

  package{"mysql-server":
    ensure => latest
  }
  
  service{ "mysql":
    ensure => running,
    require => Package["mysql-server"]
  }
  
  exec{ "allow mysql connections from all":
    user => root, group => root,
    command => "/usr/bin/mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';\"",
    require => Package["mysql-server"]
  }

  package{ "dpkg-dev":
    ensure => installed
  }

  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem1.9.1 install --no-ri --no-rdoc rake",
    require => Package["ruby1.9.1-full"],
    creates => "/var/lib/gems/1.9.1/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    command => "/usr/bin/gem1.9.1 install --no-ri --no-rdoc bundler",
    require => Package["ruby1.9.1-full"],
    creates => "/var/lib/gems/1.9.1/bin/bundle"
  }
  
  file{ "/etc/mysql/conf.d/custom.cnf":
    mode => 644, owner => root, group => root,
    ensure => file,
    require => Package["mysql-server"],
    content => "[mysqld]\nbind-address		= 0.0.0.0\n",
    notify => Service["mysql"]
  }
}

include manifest