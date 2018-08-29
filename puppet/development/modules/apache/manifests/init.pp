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
    '/home/vagrant/.ssh/config':
      mode    => '0600',
      owner   => vagrant,
      group   => vagrant,
      content => template('apache/ssh_config.erb'),
  }

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
    "$workspace/lib/tasks/tunneling.rake":
      mode    => '0644',
      owner   => $owner,
      group   => $owner,
      content => template('apache/tunneling.rake.erb'),
  }
  
  file { "/etc/ssl/secret":
    ensure => present,
    content => "authority_pass\n",
    mode => '0600', owner => root, group => root,
  }

  file { "/etc/ssl/certs/ca.srl":
    ensure => present,
    content => "01\n",
    mode => '0644', owner => root, group => root,
  }

  exec { "Generate certificate authority":
    command => "/usr/bin/openssl req -new -x509 -days 3650 -keyform PEM -keyout /etc/ssl/private/cakey.pem -outform PEM -out /etc/ssl/certs/ca.pem -passout file:/etc/ssl/secret -batch -subj \"/C=FR/ST=Bretagne/L=Rennes/O=dev/OU=Grid5000/CN=$owner/emailAddress=support-staff@lists.grid5000.fr\"",
    user => root, group => root,
		require => File["/etc/ssl/secret"],
    creates => "/etc/ssl/private/cakey.pem",
  }

  exec { "Create client key and csr":
    user => root, group => root,
    command => "/usr/bin/openssl req -new -newkey rsa:2048 -keyout /etc/ssl/certs/clientkey.pem -out /etc/ssl/clientcsr.pem  -batch -subj \"/C=FR/ST=Bretagne/L=Rennes/O=dev/OU=Grid5000/CN=client/emailAddress=support-staff@lists.grid5000.fr\" -passout file:/etc/ssl/secret",
    creates => "/etc/ssl/clientcsr.pem",
  }

  exec { "Sign client csr":
    user => root, group => root,
    require => [Exec["Create client key and csr","Generate certificate authority"], File["/etc/ssl/certs/ca.srl"]],
    command => "/usr/bin/openssl x509 -days 3650 -CA /etc/ssl/certs/ca.pem -CAkey /etc/ssl/private/cakey.pem -req -in /etc/ssl/clientcsr.pem -outform PEM -out /etc/ssl/certs/clientcert.pem  -extensions usr_cert -passin file:/etc/ssl/secret",
    creates => "/etc/ssl/certs/clientcert.pem",
  }

  exec { "Remove client key password":
    user => root, group => root,
		require => Exec["Sign client csr"],
		command => "/usr/bin/openssl rsa -in /etc/ssl/certs/clientkey.pem -out /etc/ssl/certs/clientkey_nopass.pem -passin file:/etc/ssl/secret -passout pass:''",
		creates => "/etc/ssl/certs/clientkey_nopass.pem"
  }

  exec { "Create server key and csr":
    user => root, group => root,
    command => "/usr/bin/openssl req -new -newkey rsa:2048 -keyout /etc/ssl/private/serverkey.pem -out /etc/ssl/servercsr.pem -passout file:/etc/ssl/secret -batch -subj \"/C=FR/ST=Bretagne/L=Rennes/O=dev/OU=Grid5000/CN=server/emailAddress=support-staff@lists.grid5000.fr\"",
    creates => ["/etc/ssl/servercsr.pem","/etc/ssl/private/serverkey.pem"]
  }

  exec { "Sign server csr":
    user => root, group => root,
    require => [Exec["Create server key and csr","Generate certificate authority"], File["/etc/ssl/certs/ca.srl"]],
    command => "/usr/bin/openssl x509 -days 3650 -CA /etc/ssl/certs/ca.pem -CAkey /etc/ssl/private/cakey.pem -req -in /etc/ssl/servercsr.pem -outform PEM -out /etc/ssl/certs/servercert.pem -passin file:/etc/ssl/secret",
    creates => "/etc/ssl/certs/servercert.pem",
  }

	exec { "Remove server key password":
    user => root, group => root,
		require => Exec["Sign server csr"],
		command => "/usr/bin/openssl rsa -in /etc/ssl/private/serverkey.pem -out /etc/ssl/certs/serverkey_nopass.pem -passin file:/etc/ssl/secret -passout pass:''",
		creates => "/etc/ssl/certs/serverkey_nopass.pem"
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

  exec{ "enable apache ssl module":
	  command => "/usr/sbin/a2enmod ssl ",
    notify => Service["apache2"],
    creates => "/etc/apache2/mods-enabled/ssl.load",
    require => Package["apache2-dev"];
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
