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
        # Carbon intensity for different training approaches
        TRAINING_CARBON_INTENSITY = {
          'standard' => 1.0,           # Baseline
          'mixed_precision' => 0.6,    # 40% reduction
          'quantization' => 0.5,       # 50% reduction
          'pruning' => 0.4,           # 60% reduction
          'distillation' => 0.3,      # 70% reduction
          'efficient_architecture' => 0.4  # 60% reduction
        }.freeze

        # GPU efficiency ratings (performance per watt)
        GPU_EFFICIENCY = {
          'A100' => 1.0,      # Baseline - most efficient
          'H100' => 1.2,      # 20% better than A100
          'V100' => 0.6,      # 40% less efficient
          'T4' => 0.7,        # Good for inference
          'A10G' => 0.8,      # Balanced
          'Trainium' => 1.1   # AWS custom chip
        }.freeze
      end
    end
  end
end
