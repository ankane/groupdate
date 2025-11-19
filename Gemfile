source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest"
gem "activerecord", "~> 8.1.0"

platform :ruby, :windows do
  gem "pg"
end

platform :ruby do
  gem "mysql2"
  gem "trilogy"
  gem "sqlite3"
  gem "ruby-prof", require: false
end

platform :jruby do
  gem "sqlite3-ffi"
end

platform :windows do
  gem "tzinfo-data"
end
