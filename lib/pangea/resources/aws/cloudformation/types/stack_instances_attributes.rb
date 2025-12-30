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

module Pangea
  module Resources
    module AWS
      module CloudFormation
        module Types
          # CloudFormation Stack Instances attributes
          class CloudFormationStackInstancesAttributes < Dry::Struct
            transform_keys(&:to_sym)

            # Required attributes
            attribute :stack_set_name, Resources::Types::String

            # Deployment configuration
            attribute :deployment_targets, Resources::Types::Hash.optional.default(nil)
            attribute :regions, Resources::Types::Array.of(Resources::Types::String).default([].freeze)

            # Optional attributes
            attribute :parameter_overrides, Resources::Types::Hash.default({}.freeze)
            attribute :operation_preferences, Resources::Types::Hash.optional.default(nil)
            attribute :call_as, Resources::Types::String.optional.default(nil)
            attribute :operation_id, Resources::Types::String.optional.default(nil)

            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              validate_deployment_config!(attrs)
              super(attrs)
            end

            def self.validate_deployment_config!(attrs)
              has_targets = attrs[:deployment_targets] && !attrs[:deployment_targets].empty?
              has_regions = attrs[:regions] && !attrs[:regions].empty?

              return if has_targets || has_regions

              raise Dry::Struct::Error, "Must specify either deployment_targets or regions"
            end

            private_class_method :validate_deployment_config!

            def deployment_scope
              return 'organization' if deployment_targets&.key?(:organizational_unit_ids)
              return 'accounts' if deployment_targets&.key?(:accounts)

              'regions'
            end

            def multi_region?
              regions.length > 1
            end

            def to_h
              build_hash.compact
            end

            private

            def build_hash
              {
                stack_set_name: stack_set_name,
                deployment_targets: deployment_targets,
                regions: regions.any? ? regions : nil,
                parameter_overrides: parameter_overrides.any? ? parameter_overrides : nil,
                operation_preferences: operation_preferences,
                call_as: call_as,
                operation_id: operation_id
              }
            end
          end
        end
      end
    end
  end
end
