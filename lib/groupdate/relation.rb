require "active_support/concern"

module Groupdate
  module Relation
    extend ActiveSupport::Concern

    included do
      attr_accessor :groupdate_values
    end

    def calculate(*args, &block)
      if groupdate_values
        Groupdate::Magic::Relation.process_result(self, super)
      else
        super
      end
    end
  end
end
