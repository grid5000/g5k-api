# Recipe to install a staging version on any host. The resulting installation
# will probably be largely incomplete since the host won't have server
# certificates, git reference repository, and so on. But it can be used to
# check that the package is correctly installing and running.

class install {
  require apt::allowunauthenticated
  include mysql
  include ruby
  include git

  exec {
    'apt repo':
      command     => '/usr/bin/dpkg-scanpackages . | /bin/gzip -f9 > Packages.gz',
      cwd         => '/tmp',
      user        => root,
      creates     => '/tmp/Packages.gz',
      logoutput   => on_failure;
  }

  file {
    '/etc/apt/sources.list.d/g5k-api.list':
      ensure  => file,
      mode    => '0644',
      owner   => root,
      group   => root,
      content => 'deb file:///tmp /',
      require => Exec['apt repo'],
      notify  => Exec['sources update'];
    '/etc/apt/sources.list.d/kadeploy.list':
      ensure  => file,
      mode    => '0644',
      owner   => root,
      group   => root,
      content => 'deb http://apt.grid5000.fr/kadeploy /',
      notify  => Exec['sources update']
  }

  package { 'g5k-api':
    ensure => installed,
    require => File['/etc/apt/sources.list.d/g5k-api.list'];
  }

  service {
    'g5k-api':
      ensure    => running,
      hasstatus => true,
      require   => Package['g5k-api']
  }

  exec {
    'setup db':
      command => '/usr/bin/g5k-api rake db:setup',
      require => Package['g5k-api'],
      notify => Service['g5k-api']
  }
}

include install
