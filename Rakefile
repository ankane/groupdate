require "bundler/gem_tasks"
require "rake/testtask"

ADAPTERS = %w(postgresql mysql sqlite enumerable redshift)

ADAPTERS.each do |adapter|
  namespace :test do
    task("env:#{adapter}") { ENV["ADAPTER"] = adapter }

    Rake::TestTask.new(adapter => "env:#{adapter}") do |t|
      t.description = "Run tests for #{adapter}"
      t.libs << "test"
      # TODO permit works for enumerable, just need to make tests work
      exclude = adapter == "enumerable" ? /database|multiple_group|permit/ : /enumerable/
      t.test_files = FileList["test/**/*_test.rb"].exclude(exclude)
    end
  end
end

desc "Run all adapter tests besides redshift"
task :test do
  ADAPTERS.each do |adapter|
    next if adapter == "redshift"
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test
