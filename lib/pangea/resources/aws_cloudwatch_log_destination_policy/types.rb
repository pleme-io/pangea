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
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
        # CloudWatch Log Destination Policy resource attributes with validation
        class CloudWatchLogDestinationPolicyAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :destination_name, Resources::Types::String
          attribute :access_policy, Resources::Types::String
          attribute :force_update, Resources::Types::Bool.default(false)
          
          # Validate policy JSON and structure
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate destination_name format
            if attrs[:destination_name] && !attrs[:destination_name].match?(/^[\w\-\.]+$/)
              raise Dry::Struct::Error, "destination_name must contain only alphanumeric characters, hyphens, underscores, and periods"
            end
            
            # Validate access_policy is valid JSON
            if attrs[:access_policy]
              begin
                policy = JSON.parse(attrs[:access_policy])
                
                # Validate policy structure
                unless policy.is_a?(Hash) && policy['Statement'].is_a?(Array)
                  raise Dry::Struct::Error, "access_policy must be a valid IAM policy document with Statement array"
                end
                
                # Validate each statement
                policy['Statement'].each_with_index do |statement, idx|
                  unless statement['Effect'] && statement['Action'] && statement['Resource']
                    raise Dry::Struct::Error, "Statement #{idx} must have Effect, Action, and Resource"
                  end
                  
                  # Validate Effect
                  unless %w[Allow Deny].include?(statement['Effect'])
                    raise Dry::Struct::Error, "Statement #{idx} Effect must be 'Allow' or 'Deny'"
                  end
                  
                  # Validate Action for log destinations
                  actions = Array(statement['Action'])
                  valid_actions = ['logs:PutSubscriptionFilter', 'logs:DeleteSubscriptionFilter']
                  unless actions.all? { |a| valid_actions.include?(a) || a == 'logs:*' }
                    raise Dry::Struct::Error, "Statement #{idx} contains invalid actions for log destination"
                  end
                end
              rescue JSON::ParserError => e
                raise Dry::Struct::Error, "access_policy must be valid JSON: #{e.message}"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def policy_statements
            policy = JSON.parse(access_policy)
            policy['Statement'] || []
          rescue JSON::ParserError
            []
          end
          
          def allowed_principals
            policy_statements.select { |s| s['Effect'] == 'Allow' }
                           .flat_map { |s| Array(s['Principal']).values }
                           .flatten
                           .uniq
          end
          
          def denied_principals
            policy_statements.select { |s| s['Effect'] == 'Deny' }
                           .flat_map { |s| Array(s['Principal']).values }
                           .flatten
                           .uniq
          end
          
          def allows_organization?
            policy_statements.any? do |statement|
              statement['Condition'] &&
              statement['Condition']['StringEquals'] &&
              statement['Condition']['StringEquals']['aws:PrincipalOrgID']
            end
          end
          
          def allows_all_accounts?
            allowed_principals.include?('*')
          end
          
          def allowed_account_ids
            allowed_principals.select { |p| p.match?(/^arn:aws:iam::\d{12}:root$/) }
                             .map { |arn| arn.split(':')[4] }
                             .uniq
          end
          
          def to_h
            {
              destination_name: destination_name,
              access_policy: access_policy,
              force_update: force_update
            }
          end
        end
      end
    end
  end
end