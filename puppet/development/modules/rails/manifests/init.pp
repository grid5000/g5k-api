class rails {

  # pacakges required to build native extensions
  package {[
    'libxml2-dev',  #nokogiri
    'libxslt-dev', #nokogiri
    'libicu-dev',   #charlock_holmes
    'libmysqlclient-dev', #mysql2
    'libpq-dev', #pg
		'nodejs', #rails >= 3.1
    ]:
    ensure => installed
  }
  
} #class rails