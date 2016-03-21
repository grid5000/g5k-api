# Module:: mysql
# Manifest:: database.pp
#

# Define: mysql::database
#
# Create or Remove databases
#
# Parameters:
# - $ensure: present or absent
#
define mysql::database ($ensure) {
  include 'mysql'

  case $ensure {
    present: {
      exec { "Mysql: create ${name} db":
        require => Service['mysql'],
        user    => 'root',
        command => "/bin/echo \"CREATE DATABASE ${name} CHARACTER SET utf8 COLLATE utf8_general_ci; \" | /usr/bin/mysql ",
        unless  => "/bin/echo \"show databases;\" | /usr/bin/mysql | grep '^\\s*${name}\s*'";
      }
    }
    absent: {
      exec { "Mysql: drop ${name} db":
        require => Service['mysql'],
        user    => 'root',
        command => "/bin/echo \"DROP DATABASE ${name};\" | /usr/bin/mysql ",
        onlyif  => "/bin/echo \"show databases;\" | /usr/bin/mysql | grep '^\\s*${name}\s*'";
      }
    }
    default: {
      fail "Invalid 'ensure' value '${ensure}' for mysql::database"
    }
  }
} # Define: mysql::database

