require 'pangea/shell'
# an executor is anything that follows opentofu api

module Pangea
  module Executor
    def run(command)
      Pangea::Shell.run(command)
    end
  end
end
