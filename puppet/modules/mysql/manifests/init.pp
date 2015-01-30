class mysql {
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
  
  file{ "/etc/mysql/conf.d/custom.cnf":
    mode => 644, owner => root, group => root,
    ensure => file,
    require => Package["mysql-server"],
    content => "[mysqld]\nbind-address		= 0.0.0.0\n",
    notify => Service["mysql"]
  }

  exec{ "create development database":
    user => root, group => root,
    require => Exec["allow mysql connections from all"],
    command =>  "/usr/bin/mysql -e \"create database g5kapi_development CHARACTER SET utf8 COLLATE utf8_general_ci;\"",
    creates => "/var/lib/mysql/g5kapi_development"
  }
  exec{ "create test database":
    user => root, group => root,
    require => Exec["allow mysql connections from all"],
    command =>  "/usr/bin/mysql -e \"create database g5kapi_test CHARACTER SET utf8 COLLATE utf8_general_ci;\"",
    creates => "/var/lib/mysql/g5kapi_test"
  }
  exec{ "create oar2 database":
    user => root, group => root,
    require => Exec["allow mysql connections from all"],
    command =>  "/usr/bin/mysql -e \"create database oar2 CHARACTER SET utf8 COLLATE utf8_general_ci;\"",
    creates => "/var/lib/mysql/oar2"
  }
  
}
