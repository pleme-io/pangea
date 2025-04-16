# stack is the most top level executable element

module Pangea
  class Stack
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
