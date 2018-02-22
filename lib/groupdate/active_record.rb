require "active_record"
require "groupdate/scopes"
require "groupdate/relation"

ActiveRecord::Base.send(:extend, Groupdate::Scopes)
ActiveRecord::Relation.include(Groupdate::Relation)
