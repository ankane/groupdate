require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs = ["lib"]
  t.warning = false
  t.verbose = false
  t.test_files = FileList["test/*_test.rb"]
end
