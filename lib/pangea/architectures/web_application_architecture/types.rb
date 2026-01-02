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

require 'dry-struct'
require_relative '../types'

module Pangea
  module Architectures
    module WebApplicationArchitecture
      # Types module for web application architecture configuration.
      # This module provides input/output schemas, validation, defaults,
      # and cost estimation capabilities.
      module Types
        include Dry.Types()
        include Pangea::Architectures::Types

        class << self
          # Validates web application configuration attributes
          # @param attributes [Hash] Configuration attributes to validate
          # @return [Boolean] true if validation passes
          # @raise [ArgumentError] if validation fails
          def validate_web_application_config(attributes)
            Validation.validate_web_application_config(attributes)
          end

          # Computes environment-specific default values
          # @param environment [String] The target environment
          # @return [Hash] Merged defaults for the environment
          def compute_defaults_for_environment(environment)
            Defaults.compute_defaults_for_environment(environment)
          end

          # Coerces raw input attributes into validated Input type
          # @param raw_attributes [Hash] Raw input attributes
          # @return [Hash] Coerced and validated input
          def coerce_input(raw_attributes)
            Defaults.coerce_input(raw_attributes)
          end

          # Estimates monthly cost for the given configuration
          # @param attributes [Hash] Configuration attributes
          # @return [Float] Estimated monthly cost in USD
          def estimate_monthly_cost(attributes)
            CostEstimation.estimate_monthly_cost(attributes)
          end
        end
      end
    end
  end
end

# Load sub-modules after the Types module is defined
# This ensures the module constants are available when sub-files are loaded
require_relative 'types/validation'
require_relative 'types/defaults'
require_relative 'types/cost_estimation'
require_relative 'types/input_schema'
require_relative 'types/output_schema'
