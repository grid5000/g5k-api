class ruby {
  
  package{"ruby":
    ensure => latest
  }
  
  package{"ruby-dev":
    ensure => latest
  }
  
  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem install --no-ri --no-rdoc rake",
    require => Package["ruby"],
    creates => "/usr/local/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    command => "/usr/bin/gem install --no-ri --no-rdoc bundler --version 1.7.6",
    require => Package["ruby"],
    creates => "/usr/local/bin/bundle"
  }

}
