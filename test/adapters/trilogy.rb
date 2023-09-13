if ActiveRecord::VERSION::STRING.to_f < 7.1
  require "trilogy_adapter/connection"
  ActiveRecord::Base.public_send :extend, TrilogyAdapter::Connection
end

ActiveRecord::Base.establish_connection adapter: "trilogy", database: "groupdate_test", host: "127.0.0.1"
