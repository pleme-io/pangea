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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS EventBridge Target resources
        class EventBridgeTargetAttributes < Dry::Struct
          attribute :rule, Resources::Types::String
          attribute :event_bus_name, Resources::Types::String.default('default')
          attribute :target_id, Resources::Types::String.constrained(format: /\A[a-zA-Z0-9._-]{1,64}\z/)
          attribute :arn, Resources::Types::String.constrained(format: /\Aarn:aws:/)
          attribute :role_arn, Resources::Types::String.optional.constrained(format: /\Aarn:aws:iam::/)
          attribute :input, Resources::Types::String.optional
          attribute :input_path, Resources::Types::String.optional
          attribute? :input_transformer, InputTransformer.optional
          attribute? :retry_policy, RetryPolicy.optional
          attribute? :dead_letter_config, DeadLetterConfig.optional
          attribute? :http_parameters, HttpParameters.optional
          attribute? :kinesis_parameters, KinesisParameters.optional
          attribute? :sqs_parameters, SqsParameters.optional
          attribute? :ecs_parameters, EcsParameters.optional
          attribute? :batch_parameters, BatchParameters.optional

          def self.new(attributes = {})
            attrs = super(attributes)
            validate_input_options(attrs)
            validate_target_requirements(attrs)
            attrs
          end

          def self.validate_input_options(attrs)
            input_count = [attrs.input, attrs.input_path, attrs.input_transformer].count { |x| !x.nil? }
            raise Dry::Struct::Error, 'Cannot specify multiple input options (input, input_path, input_transformer)' if input_count > 1
          end

          def self.validate_target_requirements(attrs)
            case determine_target_type(attrs.arn)
            when 'kinesis' then raise Dry::Struct::Error, 'Kinesis targets require role_arn' unless attrs.role_arn
            when 'ecs'
              raise Dry::Struct::Error, 'ECS targets require role_arn' unless attrs.role_arn
              raise Dry::Struct::Error, 'ECS targets require ecs_parameters' unless attrs.ecs_parameters
            when 'batch'
              raise Dry::Struct::Error, 'Batch targets require role_arn' unless attrs.role_arn
              raise Dry::Struct::Error, 'Batch targets require batch_parameters' unless attrs.batch_parameters
            when 'apigateway' then raise Dry::Struct::Error, 'API Gateway targets require role_arn' unless attrs.role_arn
            end
          end

          def self.determine_target_type(arn)
            case arn
            when /\Aarn:aws:lambda:/ then 'lambda'
            when /\Aarn:aws:sqs:/ then 'sqs'
            when /\Aarn:aws:sns:/ then 'sns'
            when /\Aarn:aws:kinesis:/ then 'kinesis'
            when /\Aarn:aws:ecs:/ then 'ecs'
            when /\Aarn:aws:batch:/ then 'batch'
            when /\Aarn:aws:apigateway:/ then 'apigateway'
            when /\Aarn:aws:events:/ then 'events'
            else 'unknown'
            end
          end

          def target_type = self.class.determine_target_type(arn)
          def is_lambda_target? = target_type == 'lambda'
          def is_sqs_target? = target_type == 'sqs'
          def is_sns_target? = target_type == 'sns'
          def is_kinesis_target? = target_type == 'kinesis'
          def is_ecs_target? = target_type == 'ecs'
          def is_batch_target? = target_type == 'batch'
          def is_api_gateway_target? = target_type == 'apigateway'
          def is_fifo_sqs? = is_sqs_target? && arn.end_with?('.fifo')
          def has_role? = !role_arn.nil?
          def has_input_transformation? = !input_transformer.nil?
          def has_retry_policy? = !retry_policy.nil?
          def has_dead_letter_queue? = !dead_letter_config.nil?
          def uses_default_bus? = event_bus_name == 'default'
          def uses_custom_bus? = !uses_default_bus?
          def max_retry_attempts = retry_policy&.dig(:maximum_retry_attempts) || 3
          def max_event_age_hours = retry_policy&.dig(:maximum_event_age_in_seconds)&.then { |s| s / 3600.0 }
          def target_service = target_type.upcase

          def estimated_monthly_cost
            base = { 'lambda' => 'Variable (Lambda pricing)', 'sqs' => '~$0.40 per million messages',
                     'sns' => '~$0.50 per million notifications', 'kinesis' => '~$0.014 per million records',
                     'ecs' => 'Variable (ECS task pricing)', 'batch' => 'Variable (Batch job pricing)' }[target_type] || 'Variable'
            "#{base}#{has_dead_letter_queue? ? ' + DLQ costs' : ''}"
          end

          def reliability_features
            features = []
            features << "Retry Policy (#{max_retry_attempts} attempts)" if has_retry_policy?
            features << 'Dead Letter Queue' if has_dead_letter_queue?
            features << 'Input Transformation' if has_input_transformation?
            features.empty? ? 'Basic delivery' : features.join(', ')
          end
        end
      end
    end
  end
end
