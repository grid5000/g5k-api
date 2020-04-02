class postgres {

  package{
    ['postgresql','postgresql-client']:
      ensure   => installed,
  }

  user{
    'postgres':
      require => Package['postgresql'],
      ensure => present;
  }

  file{
    '/etc/postgresql/11/main':
      ensure  => directory,
      owner   => postgres,
      group   => postgres,
      mode    => "0700",
      recurse => true,
      require => [Package['postgresql'], User['postgres']];
    '/etc/postgresql/11/main/pg_hba.conf':
      ensure  => present,
      source  => "puppet:///modules/postgres/pg_hba.conf",
      owner   => postgres,
      group   => postgres,
      mode    => "0700",
      require => Package['postgresql'],
      notify  => Service['postgresql'];
    '/etc/postgresql/11/main/postgresql.conf':
      content => template('postgres/postgres.conf.erb'),
      owner   => postgres,
      group   => postgres,
      mode    => "0700",
      require => Package['postgresql'],
      notify  => Service['postgresql'];
  }

  service{ "postgresql":
    ensure => "running",
    require => [
      Mount['/mnt/pg_stat_tmp'],
    ],
    enable => "true";
  }


  file{
    '/mnt/pg_stat_tmp':
      ensure => directory,
  }
  mount{
    '/mnt/pg_stat_tmp':
      ensure  => "mounted",
      device  => "none",
      fstype  => "tmpfs",
      options => "size=10m",
      require => File["/mnt/pg_stat_tmp"];
  }
}

