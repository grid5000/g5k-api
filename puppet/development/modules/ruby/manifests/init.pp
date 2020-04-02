class ruby {
  
  package{"ruby":
    ensure => latest
  }
  
  package{"ruby-dev":
    ensure => latest
  }
  
  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem install --no-ri --no-rdoc rake -v 12.3.2",
    require => Package["ruby"],
    creates => "/usr/local/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    # bundler version must be less than 2.0.0 until running with ruby version < 2.3.0 as with debian jessie
    command => "/usr/bin/gem install --no-ri --no-rdoc bundler --version '< 2.0.0'",
    require => Package["ruby"],
    creates => "/usr/local/bin/bundle"
  }

}
