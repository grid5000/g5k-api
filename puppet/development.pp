# This puppet manifest is just here to configure a vanilla squeeze with the
# required libs and configuration to serve as a development machine for the
# g5k-api software. Production recipes are in the Grid'5000 puppet repository.
class development {
  include apt
  include mysql
  include ruby
  include git
  include dpkg::dev

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

stage { "init": before  => Stage["main"] }

class {"apt": 
  stage => init,
}


include development
