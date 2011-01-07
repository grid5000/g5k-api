

module OAR
  class Base < ActiveRecord::Base
    establish_connection(my_config(:oar))
  end
end
