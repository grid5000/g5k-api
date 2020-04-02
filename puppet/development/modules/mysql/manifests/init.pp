class mysql {
  package{"default-mysql-server":
    ensure => latest
  }

  service{ "mysql":
    ensure => running,
    require => Package["default-mysql-server"]
  }

  exec{ "set an empty root mysql password":
    user => root, group => root,
    command => "/usr/bin/mysql -e \"SET PASSWORD FOR 'root'@'localhost' = PASSWORD('');\"",
    require => Service["mysql"]
  }

  exec{ "allow mysql connections from all":
    user => root, group => root,
    command => "/usr/bin/mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED via mysql_native_password;\"",
    require => Service["mysql"]
  }

  exec{ "allow mysql connections for g5kapi from all":
    user => root, group => root,
    command => "/usr/bin/mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'g5kapi'@'%' IDENTIFIED by 'Pe9IeCei' ;\"",
    require => Service["mysql"]
  }

  exec{ "flush privileges":
    user => root, group => root,
    command => "/usr/bin/mysql -e \"FLUSH PRIVILEGES;\"",
    require => Service["mysql"]
  }

  file{ "/etc/mysql/conf.d/custom.cnf":
    mode => "0644", owner => root, group => root,
    ensure => file,
    require => Package["default-mysql-server"],
    content => "[mysqld]\nbind-address		= 0.0.0.0\nport            = 3306\n",
    notify => Service["mysql"]
  }

}
