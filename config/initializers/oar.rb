require 'oar'

OAR::Base.extend ConfigurationHelper
OAR::Base.establish_connection(OAR::Base.my_config(:oar))
