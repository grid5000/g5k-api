class ruby {
  
  package{"ruby1.9.1-full":
    ensure => latest
  }
  
  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem1.9.1 install --no-ri --no-rdoc rake",
    require => Package["ruby1.9.1-full"],
    creates => "/var/lib/gems/1.9.1/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    command => "/usr/bin/gem1.9.1 install --no-ri --no-rdoc bundler",
    require => Package["ruby1.9.1-full"],
    creates => "/var/lib/gems/1.9.1/bin/bundle"
  }

}