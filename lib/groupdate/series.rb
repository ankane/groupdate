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

  class Calculations
    attr_reader :relation

    def initialize(relation)
      @relation = relation
    end

    def include?(method)
      # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb
      ActiveRecord::Calculations.method_defined?(method) || custom_calculations.include?(method)
    end

    def custom_calculations
      return [] if !model.respond_to?(:groupdate_calculation_methods)
      model.groupdate_calculation_methods
    end

    private

    def model
      return if !relation.respond_to?(:klass)
      relation.klass
    end
  end
end
