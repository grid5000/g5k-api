class dpkg {
  
}

class dpkg::dev inherits dpkg {
  package{ "dpkg-dev":
    ensure => installed
  }
}