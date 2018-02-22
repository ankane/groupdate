# this class is no longer needed
# keep until next major version
# for backward compatibility
module Groupdate
  class Series
    attr_accessor :magic, :relation

    def initialize(magic, relation)
      @magic = magic
      @relation = relation
    end

    def method_missing(method, *args, &block)
      if relation.respond_to?(method, true)
        result = relation.send(method, *args, &block)
        if result.is_a?(ActiveRecord::Relation)
          Groupdate::Series.new(magic, result)
        else
          result
        end
      else
        super
      end
    end

    def respond_to?(method, include_all = false)
      relation.respond_to?(method) || super
    end

    def unscoped
      @relation.unscoped
    end
  end
end
