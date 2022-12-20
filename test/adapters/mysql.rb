options = {}
if ActiveRecord::VERSION::STRING.to_f == 7.1
  options[:prepared_statements] = true
end
ActiveRecord::Base.establish_connection adapter: "mysql2", database: "groupdate_test", **options
