class apt {
  Package {
    require => Exec["sources update","Box upgrade"]
  }

  exec { "sources update":
      command => "apt-get update",
      path => "/usr/bin:/usr/sbin:/bin",
  }

  exec { "Box upgrade":
      command => "apt-get -yq upgrade",
      environment => ["DEBIAN_FRONTEND=noninteractive"],
      path => "/usr/bin:/usr/sbin:/bin:/usr/local/sbin:/sbin",
      timeout => 900;
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
