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
  include apache
  
  postgres::database {
    'oar2_dev':
      ensure => present;
  }

  postgres::database {
    'oar2_test':
      ensure => present;
  }

  exec{ "allow connections to postgres for oar":
    user => postgres,
    command => "/bin/echo \"CREATE USER oar PASSWORD 'oar'; GRANT ALL PRIVILEGES ON *.oar2_dev TO 'oar' ;GRANT ALL PRIVILEGES ON *.oar2_test TO 'oar' ;\" | /usr/bin/psql ",
    unless => "/bin/echo \"SELECT rolname FROM pg_roles;\" | /usr/bin/psql | grep oar",
    require => [Service['postgresql'],Postgres::Database['oar2_test'],Postgres::Database['oar2_dev']]
  }

  exec{ "allow connections to postgres for oarreader":
    user => postgres,
    command => "/bin/echo \"CREATE USER oarreader PASSWORD 'read'; GRANT CONNECT ON *.oar2_dev TO 'oarreader' ;GRANT CONNECT ON *.oar2_test TO 'oarreader' ; GRANT SELECT ON *.oar2_dev TO 'oarreader' ;GRANT SELECT ON *.oar2_test TO 'oarreader' ;\" | /usr/bin/psql ",
    unless => "/bin/echo \"SELECT rolname FROM pg_roles;\" | /usr/bin/psql | grep oarreader",
    require => [Service['postgresql'],Postgres::Database['oar2_test'],Postgres::Database['oar2_dev']]
  }

  exec{ "give ownership of oar2 databases to oar":
    user => postgres,
    command => "/bin/echo \"ALTER DATABASE oar2_dev OWNER TO oar; ALTER DATABASE oar2_test OWNER TO oar;\" | /usr/bin/psql ",
    unless => "/usr/bin/psql -l | grep oar2 | grep oar",
    require => Exec["allow connections to postgres for oar"]
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
    cwd => $workspace,
    command => "/bin/su -c '/usr/local/bin/bundle install' $owner",
    require => [Exec["install bundler"],Package['libxml2-dev','libxslt-dev']],
    logoutput => true,
    unless => "/bin/su -c '/usr/local/bin/bundle show' $owner"
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
