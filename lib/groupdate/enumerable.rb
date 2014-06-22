module Enumerable

  [:second, :minute, :hour, :day, :week, :month, :year, :day_of_week, :hour_of_day].each do |field|
    define_method :"group_by_#{field}" do |options = {}, &block|
      Groupdate::Magic.new(field, options).group_by(self, &block)
    end
  end

end
