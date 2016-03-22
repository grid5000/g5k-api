class ruby {
  
  package{"ruby1.9.3":
    ensure => latest
  }
  
  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem1.9.3 install --no-ri --no-rdoc rake",
    require => Package["ruby1.9.3"],
    creates => "/usr/local/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    command => "/usr/bin/gem1.9.3 install --no-ri --no-rdoc bundler --version 1.7.6",
    require => Package["ruby1.9.3"],
    creates => "/usr/local/bin/bundle"
  }

}
