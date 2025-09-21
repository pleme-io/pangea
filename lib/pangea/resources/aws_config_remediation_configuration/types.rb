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
      module Types
        # AWS Config Remediation Configuration resource attributes with validation
        class ConfigRemediationConfigurationAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :config_rule_name, Resources::Types::String
          attribute :resource_type, Resources::Types::String
          attribute :target_type, Resources::Types::String
          attribute :target_id, Resources::Types::String
          attribute :target_version, Resources::Types::String
          
          # Optional attributes
          attribute :parameters, Resources::Types::Hash.optional.default({}.freeze)
          attribute :automatic, Resources::Types::Bool.default(false)
          attribute :maximum_automatic_attempts, Resources::Types::Integer.optional.default(nil)
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate config rule name
            if attrs[:config_rule_name]
              name = attrs[:config_rule_name]
              if name.empty? || name.length > 128
                raise Dry::Struct::Error, "Config rule name must be 1-128 characters"
              end
              unless name.match?(/\A[a-zA-Z0-9_-]+\z/)
                raise Dry::Struct::Error, "Config rule name contains invalid characters"
              end
            end
            
            # Validate target type
            if attrs[:target_type]
              valid_types = ['SSM_DOCUMENT']
              unless valid_types.include?(attrs[:target_type])
                raise Dry::Struct::Error, "target_type must be one of: #{valid_types.join(', ')}"
              end
            end
            
            # Validate maximum attempts if automatic is true
            if attrs[:automatic] && attrs[:maximum_automatic_attempts]
              attempts = attrs[:maximum_automatic_attempts]
              if attempts < 1 || attempts > 25
                raise Dry::Struct::Error, "maximum_automatic_attempts must be between 1 and 25"
              end
            end
            
            super(attrs)
          end
          
          def has_parameters?
            !parameters.nil? && !parameters.empty?
          end
          
          def is_automatic?
            automatic
          end
          
          def has_max_attempts?
            !maximum_automatic_attempts.nil?
          end
          
          def estimated_monthly_cost_usd
            # SSM document execution costs
            base_executions = automatic ? 100 : 10 # More executions if automatic
            execution_cost = base_executions * 0.002 # $0.002 per execution
            
            # Additional costs for automatic remediation
            monitoring_cost = automatic ? 5.0 : 0.0
            
            (execution_cost + monitoring_cost).round(2)
          end
          
          def to_h
            hash = {
              config_rule_name: config_rule_name,
              resource_type: resource_type,
              target_type: target_type,
              target_id: target_id,
              target_version: target_version,
              automatic: automatic,
              tags: tags
            }
            
            hash[:parameters] = parameters if has_parameters?
            hash[:maximum_automatic_attempts] = maximum_automatic_attempts if has_max_attempts?
            
            hash.compact
          end
        end
      end
    end
  end
end