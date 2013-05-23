require "bundler/gem_tasks"
require "rake/testtask"

task :default => :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

namespace :test do
  Rake::TestTask.new(:postgresql) do |t|
    t.libs << "test"
    t.pattern = "test/postgresql_test.rb"
  end
  Rake::TestTask.new(:mysql) do |t|
    t.libs << "test"
    t.pattern = "test/mysql_test.rb"
  end
end
