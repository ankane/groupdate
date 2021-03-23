require "active_record"
require "groupdate/query_methods"
require "groupdate/relation"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend(Groupdate::QueryMethods)
  ActiveRecord::Relation.include(Groupdate::Relation)
end
