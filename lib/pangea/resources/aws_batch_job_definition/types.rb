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

require_relative 'types/validation'
require_relative 'types/computed'
require_relative 'types/templates'
require_relative 'types/configurations'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Batch Job Definition attributes with validation
        class BatchJobDefinitionAttributes < Dry::Struct
          include Computed
          extend Templates
          extend Configurations

          transform_keys(&:to_sym)

          # Core attributes
          attribute :job_definition_name, Resources::Types::String
          attribute :type, Resources::Types::String

          # Optional attributes
          attribute? :container_properties, Resources::Types::Hash.optional
          attribute? :node_properties, Resources::Types::Hash.optional
          attribute? :retry_strategy, Resources::Types::Hash.optional
          attribute? :timeout, Resources::Types::Hash.optional
          attribute? :propagate_tags, Resources::Types::Bool.optional
          attribute? :platform_capabilities, Resources::Types::Array.optional
          attribute? :tags, Resources::Types::Hash.optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_attributes(attrs)

            super(attrs)
          end

          def self.validate_attributes(attrs)
            Validation.validate_job_definition_name(attrs[:job_definition_name]) if attrs[:job_definition_name]

            if attrs[:type] && !%w[container multinode].include?(attrs[:type])
              raise Dry::Struct::Error, "Job definition type must be 'container' or 'multinode'"
            end

            Validation.validate_container_properties(attrs[:container_properties]) if attrs[:type] == 'container' && attrs[:container_properties]

            Validation.validate_node_properties(attrs[:node_properties]) if attrs[:type] == 'multinode' && attrs[:node_properties]

            Validation.validate_retry_strategy(attrs[:retry_strategy]) if attrs[:retry_strategy]
            Validation.validate_timeout(attrs[:timeout]) if attrs[:timeout]
            Validation.validate_platform_capabilities(attrs[:platform_capabilities]) if attrs[:platform_capabilities]
          end
        end
      end
    end
  end
end
