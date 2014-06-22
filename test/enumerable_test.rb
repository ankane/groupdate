require_relative "test_helper"

unless ActiveRecord::VERSION::MAJOR == 3 and ActiveRecord::VERSION::MINOR < 2
  class TestEnumerable < Minitest::Unit::TestCase
    include TestGroupdate

    def call_method(method, field, options)
      Hash[ User.all.to_a.send(:"group_by_#{method}", options){|u| u.send(field) }.map{|k, v| [k, v.size] } ]
    end

  end
end
