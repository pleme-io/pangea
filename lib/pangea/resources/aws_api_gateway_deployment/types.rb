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
        # API Gateway Deployment attributes with validation
        class ApiGatewayDeploymentAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :rest_api_id, Pangea::Resources::Types::String
          
          # Stage name for deployment (optional - can create deployment without stage)
          attribute :stage_name, Pangea::Resources::Types::String.optional.default(nil)
          
          # Description of the deployment
          attribute :description, Pangea::Resources::Types::String.optional.default(nil)
          
          # Stage description (only used if stage_name is provided)
          attribute :stage_description, Pangea::Resources::Types::String.optional.default(nil)
          
          # Variables for the stage
          attribute :variables, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)
          
          # Canary settings for gradual deployments  
          attribute :canary_settings, Pangea::Resources::Types::Hash.optional.default(nil)
          
          # Triggers for redeployment (helps with detecting changes)
          attribute :triggers, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate stage_name format if provided
            if attrs[:stage_name]
              unless attrs[:stage_name].match?(/^[a-zA-Z0-9_]+$/)
                raise Dry::Struct::Error, "Stage name must contain only alphanumeric characters and underscores"
              end
              
              # Common reserved stage names to avoid
              reserved_names = ['test']
              if reserved_names.include?(attrs[:stage_name].downcase)
                raise Dry::Struct::Error, "Stage name '#{attrs[:stage_name]}' is reserved by API Gateway"
              end
            end
            
            # Validate canary settings
            if attrs[:canary_settings]
              canary = attrs[:canary_settings]
              
              # Validate percent_traffic is between 0 and 100
              if canary[:percent_traffic]
                percent = canary[:percent_traffic].to_f
                if percent < 0.0 || percent > 100.0
                  raise Dry::Struct::Error, "Canary traffic percentage must be between 0.0 and 100.0"
                end
              end
              
              # Validate stage_variable_overrides is a hash
              if canary[:stage_variable_overrides] && !canary[:stage_variable_overrides].is_a?(Hash)
                raise Dry::Struct::Error, "Canary stage_variable_overrides must be a hash"
              end
              
              # Validate use_stage_cache is boolean
              if canary.key?(:use_stage_cache) && ![true, false].include?(canary[:use_stage_cache])
                raise Dry::Struct::Error, "Canary use_stage_cache must be a boolean"
              end
            end
            
            # Validate stage variables format (alphanumeric and underscores)
            if attrs[:variables]
              attrs[:variables].each do |key, _value|
                unless key.match?(/^[a-zA-Z0-9_]+$/)
                  raise Dry::Struct::Error, "Stage variable names must contain only alphanumeric characters and underscores: #{key}"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def creates_stage?
            !stage_name.nil?
          end
          
          def has_canary?
            return false unless canary_settings
            canary_settings[:percent_traffic] && canary_settings[:percent_traffic].to_f > 0
          end
          
          def canary_percentage
            return 0.0 unless has_canary?
            canary_settings[:percent_traffic].to_f
          end
          
          def has_stage_variables?
            !variables.empty?
          end
          
          # Common stage names
          def self.common_stage_names
            {
              development: 'dev',
              staging: 'staging',
              production: 'prod',
              qa: 'qa',
              uat: 'uat',
              demo: 'demo',
              sandbox: 'sandbox',
              beta: 'beta',
              alpha: 'alpha'
            }
          end
          
          # Common stage variables
          def self.common_stage_variables
            {
              # Lambda function aliases
              lambda_alias: 'lambdaAlias',
              function_name: 'functionName',
              
              # Environment indicators
              environment: 'environment',
              region: 'region',
              account_id: 'accountId',
              
              # Backend endpoints
              backend_url: 'backendUrl',
              database_name: 'databaseName',
              
              # Feature flags
              debug_mode: 'debugMode',
              enable_cache: 'enableCache',
              log_level: 'logLevel'
            }
          end
          
          # Deployment triggers for common changes
          def self.common_triggers
            {
              # Trigger on any method change
              methods: '${md5(file("api-methods.tf"))}',
              
              # Trigger on integration changes
              integrations: '${md5(file("api-integrations.tf"))}',
              
              # Trigger on model changes
              models: '${md5(file("api-models.tf"))}',
              
              # Trigger on authorizer changes
              authorizers: '${md5(file("api-authorizers.tf"))}',
              
              # Timestamp trigger for forced deployments
              timestamp: '${timestamp()}',
              
              # Git commit trigger
              git_commit: '${var.git_commit_sha}'
            }
          end
          
          # Helper to build description with metadata
          def build_description_with_metadata(metadata = {})
            parts = [description].compact
            
            metadata.each do |key, value|
              parts << "#{key}: #{value}"
            end
            
            parts.join(' | ')
          end
        end
      end
    end
  end
end