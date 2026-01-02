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
        # Validation methods for sustainable ML training inputs
        module Validations
          module_function

          def validate_dataset_size(size_gb)
            raise ArgumentError, "Dataset size must be positive" if size_gb <= 0
            raise ArgumentError, "Dataset size exceeds 10TB limit" if size_gb > 10_000
          end

          def validate_training_hours(hours)
            raise ArgumentError, "Training hours must be positive" if hours <= 0
            raise ArgumentError, "Training exceeds 7 day limit" if hours > 168
          end

          def validate_carbon_threshold(threshold)
            raise ArgumentError, "Carbon threshold must be between 0 and 1000 gCO2/kWh" unless (0..1000).include?(threshold)
          end

          def validate_model_compression(enable_compression, target_reduction)
            return unless enable_compression
            raise ArgumentError, "Target reduction must be between 0 and 1" unless (0..1).include?(target_reduction)
          end
        end

        # Delegate module methods to Types module for backward compatibility
        def self.validate_dataset_size(size_gb)
          Validations.validate_dataset_size(size_gb)
        end

        def self.validate_training_hours(hours)
          Validations.validate_training_hours(hours)
        end

        def self.validate_carbon_threshold(threshold)
          Validations.validate_carbon_threshold(threshold)
        end

        def self.validate_model_compression(enable_compression, target_reduction)
          Validations.validate_model_compression(enable_compression, target_reduction)
        end
      end
    end
  end
end
