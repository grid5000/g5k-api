# This puppet manifest is just here to configure a vanilla squeeze with the
# required libs and configuration to serve as a development machine for the
# g5k-api software. Production recipes are in the Grid'5000 puppet repository.
class development {
  include apt
  include mysql
  include postgres
  include ruby
  include git
  include dpkg::dev

  postgres::database {
    'oar2_dev':
      ensure => present;
  }
  postgres::database {
    'oar2_test':
      ensure => present;
  }

  exec{ "allow connections to postgres for root":
    user => postgres,
    command => "/bin/echo \"CREATE USER root PASSWORD 'oar'; GRANT ALL PRIVILEGES ON *.oar2_dev TO 'root' ;GRANT ALL PRIVILEGES ON *.oar2_test TO 'root' ;\" | /usr/bin/psql ",
    unless => "/bin/echo \"SELECT rolname FROM pg_roles;\" | /usr/bin/psql | grep root",
    require => Service['postgresql']
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

  file {
    "/root/.ssh":
      mode => 0700,
      owner => root,
      group => root,
      ensure => directory;
  }
}

stage { "init": before  => Stage["main"] }

class {"apt": 
  stage => init,
}


include development
