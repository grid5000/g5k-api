# This puppet manifest is just here to configure a vanilla squeeze with the
# required libs and configuration to serve as a development machine for the
# g5k-api software. Production recipes are in the Grid'5000 puppet repository.
class development {
  include apt
  include mysql
  include ruby
  include git
  include dpkg::dev
}

include development