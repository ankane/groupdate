module Groupdate
  class Series
    attr_accessor :magic, :relation

    def initialize(magic, relation)
      @magic = magic
      @relation = relation
    end

    # clone to prevent modifying original variables
    def method_missing(method, *args, &block)
      # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/relation/calculations.rb
      if ActiveRecord::Calculations.method_defined?(method) || custom_calculation_methods.include?(method)
        magic.perform(relation, method, *args, &block)
      elsif relation.respond_to?(method, true)
        Groupdate::Series.new(magic, relation.send(method, *args, &block))
      else
        super
      end
    end

    def respond_to?(method, include_all = false)
      ActiveRecord::Calculations.method_defined?(method) || relation.respond_to?(method) || super
    end

    def reverse_order_value
      nil
    end

    private

    def model
      return if !relation.respond_to?(:klass)

      relation.klass
    end

    def custom_calculation_methods
      model.try(:groupdate_calculation_methods) || []
    end
  end
end
