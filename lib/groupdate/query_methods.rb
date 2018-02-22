module Groupdate
  module QueryMethods
    Groupdate::PERIODS.each do |period|
      define_method :"group_by_#{period}" do |field, time_zone = nil, range = nil, **options|
        Groupdate::Magic::Relation.generate_relation(self,
          period: period,
          field: field,
          time_zone: time_zone,
          range: range,
          **options
        )
      end
    end

    def group_by_period(period, field, permit: nil, **options)
      # to_sym is unsafe on user input, so convert to strings
      permitted_periods = ((permit || Groupdate::PERIODS).map(&:to_sym) & Groupdate::PERIODS).map(&:to_s)
      if permitted_periods.include?(period.to_s)
        send("group_by_#{period}", field, **options)
      else
        raise ArgumentError, "Unpermitted period"
      end
    end
  end
end
