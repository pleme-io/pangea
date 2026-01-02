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

module Pangea
  module Components
    module SustainableMLTraining
      module Types
        # Enums for ML training strategies
        TrainingStrategy = Types::Coercible::String.enum(
          'carbon_aware_scheduling',    # Schedule based on carbon intensity
          'efficient_architecture',     # Use efficient model architectures
          'mixed_precision',           # FP16/BF16 training
          'gradient_checkpointing',    # Trade compute for memory
          'federated_learning'         # Distributed edge training
        )

        ModelType = Types::Coercible::String.enum(
          'computer_vision',
          'natural_language',
          'tabular_data',
          'reinforcement_learning',
          'generative_ai',
          'time_series'
        )

        ComputeOptimization = Types::Coercible::String.enum(
          'none',
          'mixed_precision',
          'quantization',
          'pruning',
          'distillation',
          'neural_architecture_search'
        )

        InstancePriority = Types::Coercible::String.enum(
          'gpu_efficient',    # A100, H100 (better perf/watt)
          'cost_optimized',   # Older GPUs, spot
          'carbon_optimized', # Graviton, renewable regions
          'balanced'          # Mix of factors
        )
      end
    end
  end
end
