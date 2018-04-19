source "https://rubygems.org"

# Specify your gem's dependencies in groupdate.gemspec
gemspec

gem "activerecord", "~> 5.2.0"

if defined?(JRUBY_VERSION)
  gem "activerecord-jdbcpostgresql-adapter", git: "https://github.com/jruby/activerecord-jdbc-adapter.git"
  gem "activerecord-jdbcmysql-adapter", git: "https://github.com/jruby/activerecord-jdbc-adapter.git"
  gem "activerecord-jdbcsqlite3-adapter", git: "https://github.com/jruby/activerecord-jdbc-adapter.git"
end
