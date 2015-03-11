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
end
