require "bundler/gem_tasks"
require "rake/testtask"

ADAPTERS = %w(postgresql mysql trilogy sqlite enumerable redshift)

ADAPTERS.each do |adapter|
  namespace :test do
    task("env:#{adapter}") { ENV["ADAPTER"] = adapter }

    Rake::TestTask.new(adapter => "env:#{adapter}") do |t|
      t.description = "Run tests for #{adapter}"
      t.libs << "test"
      exclude = adapter == "enumerable" ? /associations|column|database|multiple_group/ : /enumerable/
      t.test_files = FileList["test/**/*_test.rb"].exclude(exclude)
    end
  end
end

desc "Run all adapter tests besides redshift"
task :test do
  ADAPTERS.each do |adapter|
    next if adapter == "redshift"
    next if ["postgresql", "mysql", "trilogy"].include?(adapter) && RUBY_ENGINE == "jruby"
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test

desc "Profile call"
task :profile do
  require "active_record"
  require "sqlite3"
  require "groupdate"
  require "ruby-prof"

  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
  ActiveSupport.to_time_preserves_timezone = :zone

  ActiveRecord::Migration.create_table :users, force: true do |t|
    t.datetime :created_at
  end

  class User < ActiveRecord::Base
  end

  now = Time.now
  10000.times do |n|
    User.create!(created_at: now - n.days)
  end

  measure_mode = RubyProf::WALL_TIME # RubyProf::ALLOCATIONS
  result = RubyProf::Profile.profile(measure_mode: measure_mode) do
    User.group_by_day(:created_at, time_zone: "Pacific Time (US & Canada)").count
  end

  printer = RubyProf::GraphPrinter.new(result)
  printer.print(STDOUT, min_percent: 2)
end
