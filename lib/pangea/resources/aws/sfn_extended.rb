# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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