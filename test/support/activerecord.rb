# for debugging
if ENV["VERBOSE"]
  ActiveRecord::Base.logger = ActiveSupport::Logger.new(STDOUT)
else
  ActiveRecord::Migration.verbose = false
end

# rails does this in activerecord/lib/active_record/railtie.rb
if ActiveRecord::VERSION::MAJOR >= 7
  ActiveRecord.default_timezone = :utc
else
  ActiveRecord::Base.default_timezone = :utc
end
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
ActiveRecord::Schema.define do
  if ENV["ADAPTER"] == "redshift"
    drop_table(:users, force: :cascade) if table_exists?(:users)
    drop_table(:posts, force: :cascade) if table_exists?(:posts)

    execute "CREATE TABLE users (id INT IDENTITY(1,1) PRIMARY KEY, name VARCHAR(255), score INT, created_at DATETIME, created_on DATE);"
    execute "CREATE TABLE posts (id INT IDENTITY(1,1) PRIMARY KEY, user_id INT REFERENCES users, created_at DATETIME);"
  else
    create_table :users, force: true do |t|
      t.string :name
      t.integer :score
      t.datetime :created_at
      t.column :deleted_at, :timestamptz if ENV["ADAPTER"] == "postgresql"
      t.date :created_on
    end

    create_table :posts, force: true do |t|
      t.references :user
      t.datetime :created_at
    end
  end
end
