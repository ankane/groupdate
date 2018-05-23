require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "logger"
require "active_record"

# support
require_relative "test_database"
require_relative "test_groupdate"

Minitest::Test = Minitest::Unit::TestCase unless defined?(Minitest::Test)

ENV["TZ"] = "UTC"

# for debugging
ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT) if ENV["VERBOSE"]

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

class User < ActiveRecord::Base
  has_many :posts

  def self.custom_count
    count
  end
end

class Post < ActiveRecord::Base
end

# i18n
I18n.enforce_available_locales = true
I18n.backend.store_translations :de, date: {
  abbr_month_names: %w(Jan Feb Mar Apr Mai Jun Jul Aug Sep Okt Nov Dez).unshift(nil)
},
time: {
  formats: {special: "%b %e, %Y"}
}

# migrations
def create_tables
  ActiveRecord::Migration.verbose = false

  ActiveRecord::Migration.create_table :users, force: true do |t|
    t.string :name
    t.integer :score
    t.timestamp :created_at
    t.date :created_on
  end

  ActiveRecord::Migration.create_table :posts, force: true do |t|
    t.references :user
    t.timestamp :created_at
  end
end

def create_redshift_tables
  ActiveRecord::Migration.verbose = false

  if ActiveRecord::Migration.table_exists?(:users)
    ActiveRecord::Migration.drop_table(:users, force: :cascade)
  end

  if ActiveRecord::Migration.table_exists?(:posts)
    ActiveRecord::Migration.drop_table(:posts, force: :cascade)
  end

  ActiveRecord::Migration.execute "CREATE TABLE users (id INT IDENTITY(1,1) PRIMARY KEY, name VARCHAR(255), score INT, created_at DATETIME, created_on DATE);"

  ActiveRecord::Migration.execute "CREATE TABLE posts (id INT IDENTITY(1,1) PRIMARY KEY, user_id INT REFERENCES users, created_at DATETIME);"
end
