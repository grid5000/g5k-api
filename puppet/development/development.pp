# This puppet manifest is just here to configure a vanilla buster with the
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

  exec{ "allow connections to postgres for root":
    user => postgres,
    command => "/bin/echo \"CREATE ROLE root LOGIN; GRANT ALL PRIVILEGES ON *.oar2_dev TO 'root' ;GRANT ALL PRIVILEGES ON *.oar2_test TO 'root' ;\" | /usr/bin/psql ",
    unless => "/usr/bin/psql -l | grep root",
    require => Service["postgresql"]
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
    command => "/bin/su -c 'bundle install' $owner",
    require => [Package['bundler'],Package['libxml2-dev','libxslt-dev']],
    logoutput => true,
    unless => "/bin/su -c 'bundle show' $owner"
  }

  # Because of the way access to mysql and postgres work in
	# docker for gitlab.inria.fr
  exec { "Make sure mysql and postgres resolve to 127.0.0.1":
    user => root,
    group => root,
    command => "/bin/sed -i -e 's/^127.0.0.1\tlocalhost/127.0.0.1\tlocalhost postgres mysql/' /etc/hosts",
    unless => "/bin/grep 'postgres mysql' /etc/hosts"
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
