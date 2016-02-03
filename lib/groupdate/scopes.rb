module Groupdate
  module Scopes
    Groupdate::PERIODS.each do |period|
      define_method :"group_by_#{period}" do |field, time_zone=nil, range=nil, **options|
        options[:time_zone] ||= time_zone
        options[:range] ||= range
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
