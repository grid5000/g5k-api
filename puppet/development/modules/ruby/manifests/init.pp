class ruby {
  $ruby_packages = ['ruby', 'ruby-dev', 'rake', 'bundler']

  package{$ruby_packages:
    ensure => latest
  }
}
