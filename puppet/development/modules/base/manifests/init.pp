class base {
  exec { "Configure system locale":
    command => "/bin/echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen",
    unless  => "/usr/bin/grep '^en_US.UTF-8 UTF-8' /etc/locale.gen";
  }

  exec { "Locale generation":
    command     => "/usr/sbin/locale-gen",
    subscribe   => Exec['Configure system locale'],
    refreshonly => true;
  }
}
