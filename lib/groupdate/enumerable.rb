module Enumerable
  Groupdate::PERIODS.each do |period|
    define_method :"group_by_#{period}" do |*args, **options, &block|
      if block
        # TODO throw error in Groupdate 5
        warn "[groupdate] positional arguments are deprecated" if args.any?
        Groupdate::Magic::Enumerable.group_by(self, period, (args[0] || {}).merge(options), &block)
      elsif respond_to?(:scoping)
        scoping { @klass.send(:"group_by_#{period}", *args, **options, &block) }
      else
        raise ArgumentError, "no block given"
      end
    end
  end

  def group_by_period(period, *args, **options, &block)
    if block || !respond_to?(:scoping)
      # TODO throw error in Groupdate 5
      warn "[groupdate] positional arguments are deprecated" if args.any?
      options = (args[0] || {}).merge(options)
      # to_sym is unsafe on user input, so convert to strings
      permitted_periods = ((options.delete(:permit) || Groupdate::PERIODS).map(&:to_sym) & Groupdate::PERIODS).map(&:to_s)
      if permitted_periods.include?(period.to_s)
        send("group_by_#{period}", **options, &block)
      else
        raise ArgumentError, "Unpermitted period"
      end
    else
      scoping { @klass.send(:group_by_period, period, *args, **options, &block) }
    end
  end
end
