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
        # Input transformer configuration
        class InputTransformer < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :input_paths_map, Resources::Types::Hash.default({}.freeze)
          attribute :input_template, Resources::Types::String
          
          def to_h
            {
              input_paths_map: input_paths_map,
              input_template: input_template
            }.compact
          end
        end
        
        # Retry policy configuration
        class RetryPolicy < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :maximum_event_age_in_seconds, Resources::Types::Integer.optional.default(nil)
          attribute :maximum_retry_attempts, Resources::Types::Integer.optional.default(nil)
          
          def to_h
            hash = {}
            hash[:maximum_event_age_in_seconds] = maximum_event_age_in_seconds if maximum_event_age_in_seconds
            hash[:maximum_retry_attempts] = maximum_retry_attempts if maximum_retry_attempts
            hash.compact
          end
        end
        
        # Dead letter config
        class DeadLetterConfig < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :arn, Resources::Types::String
          
          def to_h
            { arn: arn }
          end
        end
        
        # CloudWatch Event Target resource attributes with validation
        class CloudWatchEventTargetAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :rule, Resources::Types::String
          attribute :arn, Resources::Types::String
          attribute :target_id, Resources::Types::String.optional.default(nil)
          
          # Optional attributes
          attribute :event_bus_name, Resources::Types::String.default('default')
          attribute :input, Resources::Types::String.optional.default(nil)
          attribute :input_path, Resources::Types::String.optional.default(nil)
          attribute :input_transformer, InputTransformer.optional.default(nil)
          attribute :role_arn, Resources::Types::String.optional.default(nil)
          
          # Target-specific configurations
          attribute :ecs_target, Resources::Types::Hash.optional.default(nil)
          attribute :batch_target, Resources::Types::Hash.optional.default(nil)
          attribute :kinesis_target, Resources::Types::Hash.optional.default(nil)
          attribute :sqs_target, Resources::Types::Hash.optional.default(nil)
          attribute :http_target, Resources::Types::Hash.optional.default(nil)
          attribute :run_command_targets, Resources::Types::Array.of(Resources::Types::Hash).default([].freeze)
          attribute :redshift_target, Resources::Types::Hash.optional.default(nil)
          attribute :sage_maker_pipeline_target, Resources::Types::Hash.optional.default(nil)
          
          # Error handling
          attribute :retry_policy, RetryPolicy.optional.default(nil)
          attribute :dead_letter_config, DeadLetterConfig.optional.default(nil)
          
          # Validate target configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate ARN format
            if attrs[:arn] && !attrs[:arn].match?(/^arn:aws[a-z\-]*:/) && !attrs[:arn].match?(/^\$\{/)
              raise Dry::Struct::Error, "arn must be a valid AWS ARN"
            end
            
            # Validate input options are mutually exclusive
            input_options = [:input, :input_path, :input_transformer].count { |opt| attrs[opt] }
            if input_options > 1
              raise Dry::Struct::Error, "Can only specify one of: input, input_path, or input_transformer"
            end
            
            # Validate role_arn format if provided
            if attrs[:role_arn] && !attrs[:role_arn].empty?
              unless attrs[:role_arn].match?(/^arn:aws[a-z\-]*:iam::\d{12}:role\//) ||
                     attrs[:role_arn].match?(/^\$\{/)
                raise Dry::Struct::Error, "role_arn must be a valid IAM role ARN"
              end
            end
            
            # Convert nested structures to appropriate types
            if attrs[:input_transformer] && !attrs[:input_transformer].is_a?(InputTransformer)
              attrs[:input_transformer] = InputTransformer.new(attrs[:input_transformer])
            end
            
            if attrs[:retry_policy] && !attrs[:retry_policy].is_a?(RetryPolicy)
              attrs[:retry_policy] = RetryPolicy.new(attrs[:retry_policy])
            end
            
            if attrs[:dead_letter_config] && !attrs[:dead_letter_config].is_a?(DeadLetterConfig)
              attrs[:dead_letter_config] = DeadLetterConfig.new(attrs[:dead_letter_config])
            end
            
            # Validate target-specific configurations
            if attrs[:ecs_target]
              validate_ecs_target(attrs[:ecs_target])
            end
            
            if attrs[:batch_target]
              validate_batch_target(attrs[:batch_target])
            end
            
            super(attrs)
          end
          
          def self.validate_ecs_target(ecs_target)
            unless ecs_target[:task_definition_arn]
              raise Dry::Struct::Error, "ecs_target requires task_definition_arn"
            end
          end
          
          def self.validate_batch_target(batch_target)
            unless batch_target[:job_definition] && batch_target[:job_name]
              raise Dry::Struct::Error, "batch_target requires job_definition and job_name"
            end
          end
          
          # Computed properties
          def target_service
            return :unknown unless arn
            
            case arn
            when /^arn:aws[a-z\-]*:lambda:/ then :lambda
            when /^arn:aws[a-z\-]*:sns:/ then :sns
            when /^arn:aws[a-z\-]*:sqs:/ then :sqs
            when /^arn:aws[a-z\-]*:kinesis:/ then :kinesis
            when /^arn:aws[a-z\-]*:firehose:/ then :firehose
            when /^arn:aws[a-z\-]*:logs:/ then :cloudwatch_logs
            when /^arn:aws[a-z\-]*:events:/ then :event_bus
            when /^arn:aws[a-z\-]*:states:/ then :step_functions
            when /^arn:aws[a-z\-]*:codebuild:/ then :codebuild
            when /^arn:aws[a-z\-]*:codepipeline:/ then :codepipeline
            when /^arn:aws[a-z\-]*:ecs:/ then :ecs
            when /^arn:aws[a-z\-]*:batch:/ then :batch
            when /^arn:aws[a-z\-]*:glue:/ then :glue
            when /^arn:aws[a-z\-]*:redshift:/ then :redshift
            when /^arn:aws[a-z\-]*:sagemaker:/ then :sagemaker
            else :unknown
            end
          end
          
          def requires_role?
            # Services that typically require a role
            [:ecs, :batch, :kinesis, :firehose, :step_functions, :codebuild, :codepipeline].include?(target_service)
          end
          
          def has_input_transformation?
            !input_transformer.nil?
          end
          
          def has_retry_policy?
            !retry_policy.nil?
          end
          
          def has_dead_letter_queue?
            !dead_letter_config.nil?
          end
          
          def to_h
            hash = {
              rule: rule,
              arn: arn,
              event_bus_name: event_bus_name
            }
            
            # Optional attributes
            hash[:target_id] = target_id if target_id
            hash[:input] = input if input
            hash[:input_path] = input_path if input_path
            hash[:input_transformer] = input_transformer.to_h if input_transformer
            hash[:role_arn] = role_arn if role_arn
            
            # Target-specific configurations
            hash[:ecs_target] = ecs_target if ecs_target
            hash[:batch_target] = batch_target if batch_target
            hash[:kinesis_target] = kinesis_target if kinesis_target
            hash[:sqs_target] = sqs_target if sqs_target
            hash[:http_target] = http_target if http_target
            hash[:run_command_targets] = run_command_targets if run_command_targets.any?
            hash[:redshift_target] = redshift_target if redshift_target
            hash[:sage_maker_pipeline_target] = sage_maker_pipeline_target if sage_maker_pipeline_target
            
            # Error handling
            hash[:retry_policy] = retry_policy.to_h if retry_policy
            hash[:dead_letter_config] = dead_letter_config.to_h if dead_letter_config
            
            hash.compact
          end
        end
      end
    end
  end
end