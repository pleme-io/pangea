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

require_relative 'code_generators/carbon_monitor'
require_relative 'code_generators/fleet_optimizer'
require_relative 'code_generators/migration_orchestrator'

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      # Code generation methods for Lambda functions
      module CodeGenerators
        include CarbonMonitor
        include FleetOptimizer
        include MigrationOrchestrator
      end
    end
  end
end
