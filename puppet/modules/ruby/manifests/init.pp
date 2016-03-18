class ruby {
  
  package{"ruby1.9.3":
    ensure => latest
  }
  
  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem1.9.3 install --no-ri --no-rdoc rake",
    require => Package["ruby1.9.3"],
    creates => "/var/lib/gems/1.9.3/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    command => "/usr/bin/gem1.9.3 install --no-ri --no-rdoc bundler",
    require => Package["ruby1.9.3"],
    creates => "/var/lib/gems/1.9.3/bin/bundle"
  }

}
