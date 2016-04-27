# This puppet manifest is just here to configure a vanilla squeeze with the
# required libs and configuration to serve as a development machine for the
# g5k-api software. Production recipes are in the Grid'5000 puppet repository.
class development {
  include apt
  include mysql
  include postgres
  include ruby
  include rails
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
  
  mysql::database {
    'g5kapi_dev':
      ensure => present;
  }
  
  mysql::database {
    'g5kapi_test':
      ensure => present;
  }

  exec{ "Run bundle install":
    user => root,
    group => root,
    cwd => "/vagrant",
    command => "/bin/su -c '/usr/local/bin/bundle install' vagrant",
    require => [Exec["install bundler"],Package['libxml2-dev','libxslt-dev']],
    logoutput => true,
    creates => "/vagrant/vendor/bundle"
  }
	

  file {
    "/root/.ssh":
      mode => "0700",
      owner => root,
      group => root,
      ensure => directory;
  }

  #Build dependencies
    package {[
    'libevent-dev',
    'libreadline-dev'
              ]:
    ensure => installed
  }

}

stage { "init": before  => Stage["main"] }

class {"apt": 
  stage => init,
}


include development
