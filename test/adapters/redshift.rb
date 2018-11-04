ActiveRecord::Base.establish_connection(ENV.fetch("REDSHIFT_URL"))
