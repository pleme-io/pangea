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
require_relative 'types/validators'
require_relative 'types/cost_estimator'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Config Config Rule resource attributes with validation
        class ConfigConfigRuleAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Required attributes
          attribute :name, Resources::Types::String
          attribute :source, Resources::Types::Hash

          # Optional attributes
          attribute :description, Resources::Types::String.optional.default(nil)
          attribute :input_parameters, Resources::Types::String.optional.default(nil)
          attribute :maximum_execution_frequency, Resources::Types::String.optional.default(nil)
          attribute :scope, Resources::Types::Hash.optional.default(nil)
          attribute :depends_on, Resources::Types::Array.optional.default([].freeze)

          # Tags
          attribute :tags, Resources::Types::AwsTags

          # Validate config rule name and source configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            ConfigConfigRuleValidators.validate_all(attrs)
            super(attrs)
          end

          # Computed properties
          def is_aws_managed?
            source[:owner] == 'AWS'
          end

          def is_custom_lambda?
            source[:owner] == 'CUSTOM_LAMBDA'
          end

          def is_custom_policy?
            source[:owner] == 'CUSTOM_POLICY'
          end

          def has_scope?
            !scope.nil? && !scope.empty?
          end

          def has_resource_type_scope?
            has_scope? && scope[:compliance_resource_types].is_a?(Array) && !scope[:compliance_resource_types].empty?
          end

          def has_tag_scope?
            has_scope? && (scope[:tag_key] || scope[:tag_value])
          end

          def has_periodic_execution?
            !maximum_execution_frequency.nil?
          end

          def estimated_monthly_cost_usd
            ConfigConfigRuleCostEstimator.estimate_monthly_cost(self)
          end

          def to_h
            hash = {
              name: name,
              source: source,
              tags: tags
            }

            hash[:description] = description if description
            hash[:input_parameters] = input_parameters if input_parameters
            hash[:maximum_execution_frequency] = maximum_execution_frequency if maximum_execution_frequency
            hash[:scope] = scope if has_scope?
            hash[:depends_on] = depends_on if depends_on.any?

            hash.compact
          end
        end
      end
    end
  end
end
