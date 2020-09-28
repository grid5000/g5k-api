class git {
  package{"git-core":
    ensure => latest
  }

  # To build Rugged Gem
  $rugged_build_deps = ['cmake', 'pkg-config']
  package{$rugged_build_deps:
    ensure => latest
  }
}
