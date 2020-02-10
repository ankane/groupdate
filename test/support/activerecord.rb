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

ActiveRecord::Migration.create_table :users, force: true do |t|
  t.string :name
  t.integer :score
  t.timestamp :created_at
  t.column :deleted_at, :timestamptz if ENV["ADAPTER"] == "postgresql"
  t.date :created_on
end

ActiveRecord::Migration.create_table :posts, force: true do |t|
  t.references :user
  t.timestamp :created_at
end
