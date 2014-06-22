module Enumerable

  Groupdate::FIELDS.each do |field|
    define_method :"group_by_#{field}" do |options = {}, &block|
      Groupdate::Magic.new(field, options).group_by(self, &block)
    end
  end

end
