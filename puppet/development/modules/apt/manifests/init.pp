class apt {
  Package {
    require => Exec["sources update","Box upgrade"]
  }

  exec { "sources update":
      command => "apt-get update",
      path => "/usr/bin:/usr/sbin:/bin",
      #refreshonly => true;
  }
  
  exec { "Box upgrade":
      command => "apt-get -y upgrade",
      path => "/usr/bin:/usr/sbin:/bin:/usr/local/sbin:/sbin",
      #refreshonly => true;
  }

}

class apt::allowunauthenticated inherits apt {

  file { "Apt allow unauthenticated":
      path => "/etc/apt/apt.conf.d/allow-unauthenticated",
      ensure => file,
      mode => 644, owner => root, group => root,
      content => "APT::Get::AllowUnauthenticated \"true\";\n";
  }

}
