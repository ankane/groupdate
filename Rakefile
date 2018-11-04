require "bundler/gem_tasks"
require "rake/testtask"

ADAPTERS = %w(postgresql mysql sqlite enumerable)

ADAPTERS.each do |adapter|
  namespace :test do
    task("env:#{adapter}") { ENV["ADAPTER"] = adapter }

    Rake::TestTask.new(adapter => "env:#{adapter}") do |t|
      t.libs << "test"
      test_files = FileList["test/**/*_test.rb"]
      if adapter == "enumerable"
        test_files = test_files.exclude(/database/)
      else
        test_files = test_files.exclude(/enumerable/)
      end
      t.test_files = test_files
    end
  end
end

desc "Run all adapter tests"
task :test do
  ADAPTERS.each do |adapter|
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test
