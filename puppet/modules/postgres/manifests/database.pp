# Module:: postgres
# Manifest:: database.pp
#

# Define: postgres::database
#
# Create or Remove databases
#
# Parameters:
# - $ensure: present or absent
#
define postgres::database ($ensure) {
  include 'postgres'

  case $ensure {
    present: {
      exec { "Postgresql: create ${name} db":
        require => Service['postgresql'],
        user    => 'postgres',
        command => "/bin/echo \"CREATE DATABASE ${name} WITH ENCODING 'UTF8' TEMPLATE=template0; \" | /usr/bin/psql ",
        unless  => "/bin/echo \"\\\\list\" | /usr/bin/psql | grep '^\\s*${name}\s*'";
      }
    }
    absent: {
      exec { "Postgresql: drop ${name} db":
        require => Service['postgresql'],
        user    => 'postgres',
        command => "/bin/echo \"DROP DATABASE ${name};\" | /usr/bin/psql ",
        onlyif  => "/bin/echo \"\\\\list\" | /usr/bin/psql | grep '^\\s*${name}\s*'";
      }
    }
    default: {
      fail "Invalid 'ensure' value '${ensure}' for postgres::database"
    }
  }
} # Define: postgres::database

