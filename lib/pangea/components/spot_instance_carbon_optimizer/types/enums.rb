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

require "dry-types"

module Pangea
  module Components
    module SpotInstanceCarbonOptimizer
      module Types
        include Dry.Types()

        # Enums for optimization strategies
        OptimizationStrategy = Types::Coercible::String.enum(
          'carbon_first',      # Prioritize lowest carbon regions
          'cost_first',        # Prioritize lowest cost regions
          'balanced',          # Balance carbon and cost
          'renewable_only',    # Only use renewable-heavy regions
          'follow_the_sun'     # Follow renewable energy availability
        )

        WorkloadType = Types::Coercible::String.enum(
          'stateless',         # Can migrate anytime
          'batch',             # Can checkpoint and resume
          'distributed',       # Multi-region capable
          'gpu_compute',       # GPU-intensive workloads
          'memory_intensive'   # High memory requirements
        )

        MigrationStrategy = Types::Coercible::String.enum(
          'live_migration',    # Migrate without stopping
          'checkpoint_restore', # Save state and restore
          'blue_green',        # Run parallel then switch
          'drain_and_shift'    # Gracefully drain then move
        )
      end
    end
  end
end
