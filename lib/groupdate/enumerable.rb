module Enumerable

  time_fields = %w(second minute hour day week month year)
  number_fields = %w(day_of_week hour_of_day)
  (time_fields + number_fields).each do |field|
    define_method :"group_by_#{field}" do |options = {}, &block|
      time_zone = options[:time_zone] || Groupdate.time_zone || Time.zone || "Etc/UTC"
      if time_zone.is_a?(ActiveSupport::TimeZone) or time_zone = ActiveSupport::TimeZone[time_zone]
        time_zone_object = time_zone
        time_zone = time_zone.tzinfo.name
      else
        raise "Unrecognized time zone"
      end

      # for week
      week_start = [:mon, :tue, :wed, :thu, :fri, :sat, :sun].index((options[:week_start] || options[:start] || Groupdate.week_start).to_sym)
      if field == "week" and !week_start
        raise "Unrecognized :week_start option"
      end

      # for day
      day_start = (options[:day_start] || Groupdate.day_start).to_i

      range = options.has_key?(:range) ? options[:range] : true

      Groupdate::Series.new(self, field, nil, time_zone_object, range, week_start, day_start, 0, options.slice(:reverse)).perform(:group_by, &block)
    end
  end

end
