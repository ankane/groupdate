module Groupdate
  module Scopes
    Groupdate::PERIODS.each do |period|
      define_method :"group_by_#{period}" do |field, *args|
        args = args.dup
        options = args[-1].is_a?(Hash) ? args.pop : {}
        options[:time_zone] ||= args[0] unless args[0].nil?
        options[:range] ||= args[1] unless args[1].nil?

        Groupdate::Magic.new(period, options).relation(field, self)
      end
    end

    def group_by_period(period, field, options = {})
      # to_sym is unsafe on user input, so convert to strings
      permitted_periods = ((options[:permit] || Groupdate::PERIODS).map(&:to_sym) & Groupdate::PERIODS).map(&:to_s)
      if permitted_periods.include?(period.to_s)
        send("group_by_#{period}", field, options)
      else
        raise ArgumentError, "Unpermitted period"
      end
    end
  end
end
