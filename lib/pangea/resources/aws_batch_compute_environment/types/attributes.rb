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
require 'pangea/resources/types'
require_relative 'validators'
require_relative 'helpers'
require_relative 'templates'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Batch Compute Environment attributes with validation
        class BatchComputeEnvironmentAttributes < Dry::Struct
          include BatchComputeEnvironmentHelpers
          extend BatchComputeEnvironmentTemplates
          extend BatchInstanceTypes

          transform_keys(&:to_sym)

          # Core attributes
          attribute :compute_environment_name, Resources::Types::String
          attribute :type, Resources::Types::String

          # Optional attributes
          attribute? :state, Resources::Types::String.optional.default("ENABLED")
          attribute? :service_role, Resources::Types::String.optional
          attribute? :compute_resources, Resources::Types::Hash.optional
          attribute? :tags, Resources::Types::Hash.optional

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            if attrs[:compute_environment_name]
              BatchComputeEnvironmentValidators.validate_compute_environment_name(
                attrs[:compute_environment_name]
              )
            end

            if attrs[:type] && !%w[MANAGED UNMANAGED].include?(attrs[:type])
              raise Dry::Struct::Error, "Compute environment type must be 'MANAGED' or 'UNMANAGED'"
            end

            if attrs[:state] && !%w[ENABLED DISABLED].include?(attrs[:state])
              raise Dry::Struct::Error, "Compute environment state must be 'ENABLED' or 'DISABLED'"
            end

            if attrs[:type] == "MANAGED" && attrs[:compute_resources]
              BatchComputeEnvironmentValidators.validate_compute_resources(attrs[:compute_resources])
            end

            if attrs[:type] == "UNMANAGED" && attrs[:compute_resources]
              raise Dry::Struct::Error, "UNMANAGED compute environments cannot have compute_resources"
            end

            super(attrs)
          end

          # Delegate template methods for backward compatibility
          class << self
            def validate_vpc_configuration(vpc_config)
              BatchComputeEnvironmentValidators.validate_vpc_configuration(vpc_config)
            end

            def validate_instance_types(instance_types)
              BatchComputeEnvironmentValidators.validate_instance_types(instance_types)
            end
          end
        end
      end
    end
  end
end
