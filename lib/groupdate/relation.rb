require "active_support/concern"

module Groupdate
  module Relation
    extend ActiveSupport::Concern

    included do
      attr_accessor :groupdate_values
    end

    def calculate(*args, &block)
      if groupdate_values
        # TODO in next major version
        # pass default based on operation
        Groupdate::Magic::Relation.process_result(self, super, default_value: 0)
      else
        super
      end
    end
  end
end
