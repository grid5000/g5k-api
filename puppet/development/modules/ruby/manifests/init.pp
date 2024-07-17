class ruby {
  $packages = ['ruby', 'ruby-dev', 'build-essential']

  package{$packages:
    ensure => latest
  }

  exec { "install rake":
    user => root, group => root,
    command => "/usr/bin/gem install --no-document rake",
    require => Package["ruby"],
    creates => "/usr/local/bin/rake"
  }

  exec { "install bundler":
    user => root, group => root,
    command => "/usr/bin/gem install --no-document bundler -v 2.3.22",
    require => Package["ruby"],
    creates => "/usr/local/bin/bundler"
  }
}
