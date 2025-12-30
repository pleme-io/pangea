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
          # CloudFormation Stack Set Instance attributes
          class CloudFormationStackSetInstanceAttributes < Dry::Struct
            transform_keys(&:to_sym)

            # Required attributes
            attribute :stack_set_name, Resources::Types::String

            # Target specification (for SELF_MANAGED)
            attribute :account_id, Resources::Types::String.optional.default(nil)
            attribute :region, Resources::Types::String.optional.default(nil)

            # Organizational Units (for SERVICE_MANAGED)
            attribute :deployment_targets, Resources::Types::Hash.optional.default(nil)

            # Optional attributes
            attribute :parameter_overrides, Resources::Types::Hash.default({}.freeze)
            attribute :retain_stack, Resources::Types::Bool.default(false)
            attribute :operation_preferences, Resources::Types::Hash.optional.default(nil)
            attribute :call_as, Resources::Types::String.optional.default(nil)

            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              validate_deployment_target!(attrs)
              super(attrs)
            end

            def self.validate_deployment_target!(attrs)
              has_account_region = attrs[:account_id] && attrs[:region]
              has_deployment_targets = attrs[:deployment_targets]

              unless has_account_region || has_deployment_targets
                raise Dry::Struct::Error, "Must specify either account_id+region or deployment_targets"
              end

              return unless has_account_region && has_deployment_targets

              raise Dry::Struct::Error, "Cannot specify both account_id+region and deployment_targets"
            end

            private_class_method :validate_deployment_target!

            def organization_deployment?
              !deployment_targets.nil?
            end

            def account_deployment?
              account_id && region
            end

            def to_h
              build_hash.compact
            end

            private

            def build_hash
              {
                stack_set_name: stack_set_name,
                account_id: account_id,
                region: region,
                deployment_targets: deployment_targets,
                parameter_overrides: parameter_overrides.any? ? parameter_overrides : nil,
                retain_stack: retain_stack,
                operation_preferences: operation_preferences,
                call_as: call_as
              }
            end
          end
        end
      end
    end
  end
end
