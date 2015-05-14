module Enumerable
  Groupdate::FIELDS.each do |field|
    define_method :"group_by_#{field}" do |options = {}, &block|
      if block
        Groupdate::Magic.new(field, options).group_by(self, &block)
      else
        raise ArgumentError, "no block given"
      end
    end
  end

  def group_by_period(period, options = {}, &block)
    # to_sym is unsafe on user input, so convert to strings
    permitted_periods = ((options[:permit] || Groupdate::FIELDS).map(&:to_sym) & Groupdate::FIELDS).map(&:to_s)
    if permitted_periods.include?(period.to_s)
      send("group_by_#{period}", options, &block)
    else
      raise ArgumentError, "Unpermitted period"
    end
  end
end
