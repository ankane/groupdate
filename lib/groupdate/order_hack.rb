module Groupdate
  class OrderHack < String
    attr_reader :field, :time_zone

    def initialize(str, field, time_zone)
      super(str)
      @field = field
      @time_zone = time_zone
    end
  end
end
