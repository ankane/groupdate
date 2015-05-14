module Groupdate
  module Scopes
    Groupdate::FIELDS.each do |field|
      define_method :"group_by_#{field}" do |*args|
        args = args.dup
        options = args[-1].is_a?(Hash) ? args.pop : {}
        options[:time_zone] ||= args[1] unless args[1].nil?
        options[:range] ||= args[2] unless args[2].nil?

        Groupdate::Magic.new(field, options).relation(args[0], self)
      end
    end

    def group_by_period(period, field, options = {})
      # to_sym is unsafe on user input, so convert to strings
      permitted_periods = ((options[:permit] || Groupdate::FIELDS).map(&:to_sym) & Groupdate::FIELDS).map(&:to_s)
      if permitted_periods.include?(period.to_s)
        send("group_by_#{period}", field, options)
      else
        raise ArgumentError, "Unpermitted period"
      end
    end
  end
end
