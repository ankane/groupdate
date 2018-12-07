# for debugging
if ENV["VERBOSE"]
  ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
else
  ActiveRecord::Migration.verbose = false
end

# rails does this in activerecord/lib/active_record/railtie.rb
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true

class User < ActiveRecord::Base
  has_many :posts

  alias_attribute :signed_up_at, :created_at

  def self.custom_count
    count
  end
end

class Post < ActiveRecord::Base
end

# migrations
if ENV["ADAPTER"] == "redshift"
  if ActiveRecord::Migration.table_exists?(:users)
    ActiveRecord::Migration.drop_table(:users, force: :cascade)
  end

  if ActiveRecord::Migration.table_exists?(:posts)
    ActiveRecord::Migration.drop_table(:posts, force: :cascade)
  end

  ActiveRecord::Migration.execute "CREATE TABLE users (id INT IDENTITY(1,1) PRIMARY KEY, name VARCHAR(255), score INT, created_at DATETIME, created_on DATE);"

  ActiveRecord::Migration.execute "CREATE TABLE posts (id INT IDENTITY(1,1) PRIMARY KEY, user_id INT REFERENCES users, created_at DATETIME);"
else
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
