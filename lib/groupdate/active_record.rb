require "active_record"
require "groupdate/scopes"
require "groupdate/relation"

ActiveRecord::Base.extend(Groupdate::Scopes)
ActiveRecord::Relation.include(Groupdate::Relation)
