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
    require => Service["mysql"]
  }

  exec{ "allow mysql connections for g5kapi from all":
    user => root, group => root,
    command => "/usr/bin/mysql -e \"GRANT ALL PRIVILEGES ON *.* TO 'g5kapi'@'%' IDENTIFIED by 'Pe9IeCei' ;\"",
    require => Service["mysql"]
  }

  file{ "/etc/mysql/conf.d/custom.cnf":
    mode => "0644", owner => root, group => root,
    ensure => file,
    require => Package["mysql-server"],
    content => "[mysqld]\nbind-address		= 0.0.0.0\nport            = 3306\n",
    notify => Service["mysql"]
  }

}
