module Groupdate
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
