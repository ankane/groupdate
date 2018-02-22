module Groupdate
  module Calculations
    def calculate(*args, &block)
      if groupdate_values
        Groupdate::Magic.unwind(self, :calculate, *args, &block)
      else
        super
      end
    end
  end
end
