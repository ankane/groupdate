module Groupdate
  class Series
    attr_accessor :magic, :relation

    def initialize(magic, relation)
      @magic = magic
      @relation = relation
      @calculations = Groupdate::Calculations.new(relation)
    end

    # clone to prevent modifying original variables
    def method_missing(method, *args, &block)
      if @calculations.include?(method)
        magic.perform(relation, method, *args, &block)
      elsif relation.respond_to?(method, true)
        Groupdate::Series.new(magic, relation.send(method, *args, &block))
      else
        super
      end
    end

    def respond_to?(method, include_all = false)
      @calculations.include?(method) || relation.respond_to?(method) || super
    end

    def reverse_order_value
      nil
    end
  end
end
