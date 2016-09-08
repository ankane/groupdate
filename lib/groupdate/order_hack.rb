module Groupdate
  class OrderHack < String
    attr_reader :field, :time_zone

    def initialize(str, field, time_zone)
      super(str)
      @field = field.to_s
      @time_zone = time_zone
    end
  end
end
