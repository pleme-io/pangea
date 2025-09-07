# frozen_string_literal: true

require_relative 'sfn_extended/activity'
require_relative 'sfn_extended/state_machine_alias'
require_relative 'sfn_extended/map_run'
require_relative 'sfn_extended/express_logging_configuration'
require_relative 'sfn_extended/execution'
require_relative 'sfn_extended/activity_task'
require_relative 'sfn_extended/state_machine_version'

module Pangea
  module Resources
    module AWS
      # Extended Step Functions resources for workflow orchestration
      module SfnExtended
        include Activity
        include StateMachineAlias
        include MapRun
        include ExpressLoggingConfiguration
        include Execution
        include ActivityTask
        include StateMachineVersion
      end
    end
  end
end