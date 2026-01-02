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

require_relative 'types/input_transformer'
require_relative 'types/retry_policy'
require_relative 'types/dead_letter_config'
require_relative 'types/target_service_detection'
require_relative 'types/validators'

module Pangea
  module Resources
    module AWS
      module Types
        # CloudWatch Event Target resource attributes with validation
        class CloudWatchEventTargetAttributes < Dry::Struct
          include TargetServiceDetection

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

            CloudWatchEventTargetValidators.validate_arn(attrs[:arn])
            CloudWatchEventTargetValidators.validate_input_options(attrs)
            CloudWatchEventTargetValidators.validate_role_arn(attrs[:role_arn])
            CloudWatchEventTargetValidators.validate_ecs_target(attrs[:ecs_target])
            CloudWatchEventTargetValidators.validate_batch_target(attrs[:batch_target])

            # Convert nested structures to appropriate types
            attrs = convert_nested_structures(attrs)

            super(attrs)
          end

          def self.convert_nested_structures(attrs)
            attrs = attrs.dup

            if attrs[:input_transformer] && !attrs[:input_transformer].is_a?(InputTransformer)
              attrs[:input_transformer] = InputTransformer.new(attrs[:input_transformer])
            end

            if attrs[:retry_policy] && !attrs[:retry_policy].is_a?(RetryPolicy)
              attrs[:retry_policy] = RetryPolicy.new(attrs[:retry_policy])
            end

            if attrs[:dead_letter_config] && !attrs[:dead_letter_config].is_a?(DeadLetterConfig)
              attrs[:dead_letter_config] = DeadLetterConfig.new(attrs[:dead_letter_config])
            end

            attrs
          end

          def to_h
            build_required_hash
              .merge(build_optional_hash)
              .merge(build_target_config_hash)
              .merge(build_error_handling_hash)
              .compact
          end

          private

          def build_required_hash
            {
              rule: rule,
              arn: arn,
              event_bus_name: event_bus_name
            }
          end

          def build_optional_hash
            hash = {}
            hash[:target_id] = target_id if target_id
            hash[:input] = input if input
            hash[:input_path] = input_path if input_path
            hash[:input_transformer] = input_transformer.to_h if input_transformer
            hash[:role_arn] = role_arn if role_arn
            hash
          end

          def build_target_config_hash
            hash = {}
            hash[:ecs_target] = ecs_target if ecs_target
            hash[:batch_target] = batch_target if batch_target
            hash[:kinesis_target] = kinesis_target if kinesis_target
            hash[:sqs_target] = sqs_target if sqs_target
            hash[:http_target] = http_target if http_target
            hash[:run_command_targets] = run_command_targets if run_command_targets.any?
            hash[:redshift_target] = redshift_target if redshift_target
            hash[:sage_maker_pipeline_target] = sage_maker_pipeline_target if sage_maker_pipeline_target
            hash
          end

          def build_error_handling_hash
            hash = {}
            hash[:retry_policy] = retry_policy.to_h if retry_policy
            hash[:dead_letter_config] = dead_letter_config.to_h if dead_letter_config
            hash
          end
        end
      end
    end
  end
end
