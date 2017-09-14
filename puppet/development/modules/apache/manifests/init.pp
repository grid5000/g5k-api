class apache {

  package{ ["apache2", "apache2-dev"]:
    ensure => latest
  }

  service{ "apache2":
    ensure => running,
    hasrestart => true,
    require => Package["apache2"]
  }

  #This is used by the template defining the proxy to iterate
  # through the list of sites
  $sites = [
    'grenoble',
    'lille',
    'lyon',
    'luxembourg',
    'nancy',
    'rennes',
    'sophia',
    'nantes'
  ]

  file {
    '/etc/apache2/sites-available/api-proxy-dev.conf':
      mode    => '0644',
      owner   => root,
      group   => root,
      content => template('apache/api-proxy-dev.erb'),
      notify  => Service['apache2'],
      require => [Package['apache2']];
  }

  file {
    '/vagrant/lib/tasks/tunneling.rake':
      mode    => '0644',
      owner   => root,
      group   => root,
      content => template('apache/tunneling.rake.erb'),
  }
  
  exec {
    "enable site api-proxy-dev":
      command => "/usr/sbin/a2ensite api-proxy-dev",
      unless => "/usr/bin/test -f /etc/apache2/sites-enabled/api-proxy-dev.conf",
      notify => Service["apache2"],
      require => [Package["apache2"], File["/etc/apache2/sites-available/api-proxy-dev.conf"]];
  }

  exec {
    "enable module proxy":
      command => "/usr/sbin/a2enmod proxy",
      unless => "/bin/ls /etc/apache2/mods-enabled | grep proxy",
      before => Service["apache2"],
      notify => Service["apache2"],
      require => Package["apache2"];
  }

  exec {
    "enable module proxy_http":
      command => "/usr/sbin/a2enmod proxy_http",
      unless => "/bin/ls /etc/apache2/mods-enabled | grep proxy_http",
      before => Service["apache2"],
      notify => Service["apache2"],
      require => Package["apache2"];
  }

  exec {
    "enable module rewrite":
      command => "/usr/sbin/a2enmod rewrite",
      unless => "/bin/ls /etc/apache2/mods-enabled | grep rewrite",
      before => Service["apache2"],
      notify => Service["apache2"],
      require => Package["apache2"];
  }

  file {
    '/etc/apache2/conf-available/deflate.conf':
      mode    => '0644',
      owner   => root,
      group   => root,
      source  => 'puppet:///modules/apache/deflate.conf',
      require => Package['apache2'],
      notify  => Service['apache2'];
  }

  exec {
    "enable module deflate":
      command => "/usr/sbin/a2enmod deflate",
      unless => "/bin/ls /etc/apache2/mods-enabled | grep deflate",
      before => Service["apache2"],
      notify => Service["apache2"],
      require => Package["apache2"];
  }

  exec {
    "enable module deflate configuration":
      command => "/usr/sbin/a2enconf deflate",
      unless => "/bin/ls /etc/apache2/conf-enabled | grep deflate",
      before => Service["apache2"],
      notify => Service["apache2"],
      require => Package["apache2"];
    }
  
  exec {
    "enable module headers":
      command => "/usr/sbin/a2enmod headers",
      unless => "/bin/ls /etc/apache2/mods-enabled | grep headers",
      before => Service["apache2"],
      notify => Service["apache2"],
      require => Package["apache2"];
  }

}
