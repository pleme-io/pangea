# frozen_string_literal: true

require 'pangea/resources/types'
require 'json'

module Pangea
  module Resources
    module AWS
      module Types
      # Input transformation validation for EventBridge targets
      InputTransformer = Types::Hash.schema(
        input_paths?: Types::Hash.map(String, String).optional,
        input_template: Types::String
      ).constructor { |value|
        # Validate input template is valid JSON-like template
        template = value[:input_template]
        
        # Basic validation that template contains valid substitution patterns
        unless template.match?(/\{.*\}/) || template == '"{}"'
          raise Dry::Types::ConstraintError, "Input template must contain substitution patterns or be empty JSON object"
        end
        
        value
      }

      # Retry policy validation for EventBridge targets
      RetryPolicy = Types::Hash.schema(
        maximum_retry_attempts?: Types::Integer.optional.constrained(gteq: 0, lteq: 185),
        maximum_event_age_in_seconds?: Types::Integer.optional.constrained(gteq: 60, lteq: 86400)
      )

      # Dead letter queue configuration
      DeadLetterConfig = Types::Hash.schema(
        arn?: Types::String.optional.constrained(format: /\Aarn:aws:sqs:/)
      )

      # HTTP parameters for API destinations
      HttpParameters = Types::Hash.schema(
        path_parameter_values?: Types::Hash.map(String, String).optional,
        header_parameters?: Types::Hash.map(String, String).optional,
        query_string_parameters?: Types::Hash.map(String, String).optional
      )

      # Kinesis parameters
      KinesisParameters = Types::Hash.schema(
        partition_key_path?: Types::String.optional
      )

      # SQS parameters
      SqsParameters = Types::Hash.schema(
        message_group_id?: Types::String.optional
      )

      # ECS parameters
      EcsParameters = Types::Hash.schema(
        task_definition_arn: Types::String.constrained(format: /\Aarn:aws:ecs:/),
        task_count?: Types::Integer.optional.constrained(gteq: 1, lteq: 10),
        launch_type?: Types::String.enum("EC2", "FARGATE", "EXTERNAL").optional,
        network_configuration?: Types::Hash.schema(
          awsvpc_configuration?: Types::Hash.schema(
            subnets: Types::Array.of(Types::String).constrained(min_size: 1),
            security_groups?: Types::Array.of(Types::String).optional,
            assign_public_ip?: Types::String.enum("ENABLED", "DISABLED").optional
          ).optional
        ).optional,
        platform_version?: Types::String.optional,
        group?: Types::String.optional,
        capacity_provider_strategy?: Types::Array.of(
          Types::Hash.schema(
            capacity_provider: Types::String,
            weight?: Types::Integer.optional.constrained(gteq: 0, lteq: 1000),
            base?: Types::Integer.optional.constrained(gteq: 0, lteq: 100000)
          )
        ).optional,
        placement_constraint?: Types::Array.of(
          Types::Hash.schema(
            type?: Types::String.enum("distinctInstance", "memberOf").optional,
            expression?: Types::String.optional
          )
        ).optional,
        placement_strategy?: Types::Array.of(
          Types::Hash.schema(
            type?: Types::String.enum("random", "spread", "binpack").optional,
            field?: Types::String.optional
          )
        ).optional,
        tags?: Types::AwsTags.optional
      )

      # Batch parameters
      BatchParameters = Types::Hash.schema(
        job_definition: Types::String,
        job_name: Types::String,
        array_properties?: Types::Hash.schema(
          size?: Types::Integer.optional.constrained(gteq: 2, lteq: 10000)
        ).optional,
        retry_strategy?: Types::Hash.schema(
          attempts?: Types::Integer.optional.constrained(gteq: 1, lteq: 10)
        ).optional
      )

      # Type-safe attributes for AWS EventBridge Target resources
      class EventBridgeTargetAttributes < Dry::Struct
        # Rule name that this target is attached to (required)
        attribute :rule, Resources::Types::String

        # Event bus name (defaults to "default")
        attribute :event_bus_name, Resources::Types::String.default("default")

        # Target ID (unique within the rule)
        attribute :target_id, Resources::Types::String.constrained(format: /\A[a-zA-Z0-9._-]{1,64}\z/)

        # Target ARN (required)
        attribute :arn, Resources::Types::String.constrained(format: /\Aarn:aws:/)

        # Role ARN for target invocation
        attribute :role_arn, Resources::Types::String.optional.constrained(format: /\Aarn:aws:iam::/)

        # Input configuration (mutually exclusive with input_transformer)
        attribute :input, Resources::Types::String.optional
        attribute :input_path, Resources::Types::String.optional
        attribute? :input_transformer, InputTransformer.optional

        # Retry configuration
        attribute? :retry_policy, RetryPolicy.optional

        # Dead letter queue
        attribute? :dead_letter_config, DeadLetterConfig.optional

        # Service-specific parameters
        attribute? :http_parameters, HttpParameters.optional
        attribute? :kinesis_parameters, KinesisParameters.optional
        attribute? :sqs_parameters, SqsParameters.optional
        attribute? :ecs_parameters, EcsParameters.optional
        attribute? :batch_parameters, BatchParameters.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate mutually exclusive input options
          input_count = [attrs.input, attrs.input_path, attrs.input_transformer].count { |x| !x.nil? }
          if input_count > 1
            raise Dry::Struct::Error, "Cannot specify multiple input options (input, input_path, input_transformer)"
          end

          # Validate target type consistency
          target_type = determine_target_type(attrs.arn)
          
          case target_type
          when 'lambda'
            # Lambda targets don't need role_arn but can have it for cross-account
            # No specific parameters needed
          when 'sqs'
            # SQS targets may need role_arn for cross-account or FIFO queues
            if attrs.arn.end_with?('.fifo') && !attrs.sqs_parameters&.dig(:message_group_id)
              # FIFO queues should have message_group_id, but it's not strictly required
            end
          when 'sns'
            # SNS targets may need role_arn for cross-account
          when 'kinesis'
            # Kinesis targets need role_arn and may have kinesis_parameters
            unless attrs.role_arn
              raise Dry::Struct::Error, "Kinesis targets require role_arn"
            end
          when 'ecs'
            # ECS targets need role_arn and ecs_parameters
            unless attrs.role_arn
              raise Dry::Struct::Error, "ECS targets require role_arn"
            end
            unless attrs.ecs_parameters
              raise Dry::Struct::Error, "ECS targets require ecs_parameters"
            end
          when 'batch'
            # Batch targets need role_arn and batch_parameters
            unless attrs.role_arn
              raise Dry::Struct::Error, "Batch targets require role_arn"
            end
            unless attrs.batch_parameters
              raise Dry::Struct::Error, "Batch targets require batch_parameters"
            end
          when 'apigateway'
            # API Gateway targets need role_arn
            unless attrs.role_arn
              raise Dry::Struct::Error, "API Gateway targets require role_arn"
            end
          end

          attrs
        end

        # Helper method to determine target type from ARN
        def self.determine_target_type(arn)
          case arn
          when /\Aarn:aws:lambda:/
            'lambda'
          when /\Aarn:aws:sqs:/
            'sqs'
          when /\Aarn:aws:sns:/
            'sns'
          when /\Aarn:aws:kinesis:/
            'kinesis'
          when /\Aarn:aws:ecs:/
            'ecs'
          when /\Aarn:aws:batch:/
            'batch'
          when /\Aarn:aws:apigateway:/
            'apigateway'
          when /\Aarn:aws:events:/
            'events'
          else
            'unknown'
          end
        end

        # Helper methods
        def target_type
          self.class.determine_target_type(arn)
        end

        def is_lambda_target?
          target_type == 'lambda'
        end

        def is_sqs_target?
          target_type == 'sqs'
        end

        def is_sns_target?
          target_type == 'sns'
        end

        def is_kinesis_target?
          target_type == 'kinesis'
        end

        def is_ecs_target?
          target_type == 'ecs'
        end

        def is_batch_target?
          target_type == 'batch'
        end

        def is_api_gateway_target?
          target_type == 'apigateway'
        end

        def is_fifo_sqs?
          is_sqs_target? && arn.end_with?('.fifo')
        end

        def has_role?
          !role_arn.nil?
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

        def uses_default_bus?
          event_bus_name == "default"
        end

        def uses_custom_bus?
          !uses_default_bus?
        end

        def max_retry_attempts
          retry_policy&.dig(:maximum_retry_attempts) || 3
        end

        def max_event_age_hours
          return nil unless retry_policy&.dig(:maximum_event_age_in_seconds)
          retry_policy[:maximum_event_age_in_seconds] / 3600.0
        end

        def estimated_monthly_cost
          base_cost = case target_type
                     when 'lambda'
                       "Variable (Lambda pricing)"
                     when 'sqs'
                       "~$0.40 per million messages"
                     when 'sns'
                       "~$0.50 per million notifications"
                     when 'kinesis'
                       "~$0.014 per million records"
                     when 'ecs'
                       "Variable (ECS task pricing)"
                     when 'batch'
                       "Variable (Batch job pricing)"
                     else
                       "Variable"
                     end
          
          dlq_cost = has_dead_letter_queue? ? " + DLQ costs" : ""
          "#{base_cost}#{dlq_cost}"
        end

        def target_service
          target_type.upcase
        end

        def reliability_features
          features = []
          features << "Retry Policy (#{max_retry_attempts} attempts)" if has_retry_policy?
          features << "Dead Letter Queue" if has_dead_letter_queue?
          features << "Input Transformation" if has_input_transformation?
          features.empty? ? "Basic delivery" : features.join(", ")
        end
      end

      # Common EventBridge Target configurations
      module EventBridgeTargetConfigs
        # Lambda function target
        def self.lambda_target(rule:, target_id:, function_arn:, input: nil)
          {
            rule: rule,
            target_id: target_id,
            arn: function_arn,
            input: input
          }.compact
        end

        # SQS queue target
        def self.sqs_target(rule:, target_id:, queue_arn:, message_group_id: nil)
          config = {
            rule: rule,
            target_id: target_id,
            arn: queue_arn
          }
          
          if message_group_id
            config[:sqs_parameters] = { message_group_id: message_group_id }
          end
          
          config
        end

        # SNS topic target
        def self.sns_target(rule:, target_id:, topic_arn:, role_arn: nil)
          {
            rule: rule,
            target_id: target_id,
            arn: topic_arn,
            role_arn: role_arn
          }.compact
        end

        # Kinesis stream target
        def self.kinesis_target(rule:, target_id:, stream_arn:, role_arn:, partition_key_path: nil)
          config = {
            rule: rule,
            target_id: target_id,
            arn: stream_arn,
            role_arn: role_arn
          }
          
          if partition_key_path
            config[:kinesis_parameters] = { partition_key_path: partition_key_path }
          end
          
          config
        end

        # ECS task target
        def self.ecs_target(rule:, target_id:, task_definition_arn:, role_arn:, 
                           cluster_arn: nil, launch_type: "FARGATE", task_count: 1,
                           subnets: [], security_groups: [])
          ecs_params = {
            task_definition_arn: task_definition_arn,
            task_count: task_count,
            launch_type: launch_type
          }
          
          if launch_type == "FARGATE" && subnets.any?
            ecs_params[:network_configuration] = {
              awsvpc_configuration: {
                subnets: subnets,
                security_groups: security_groups,
                assign_public_ip: "DISABLED"
              }
            }
          end
          
          {
            rule: rule,
            target_id: target_id,
            arn: cluster_arn || "arn:aws:ecs",
            role_arn: role_arn,
            ecs_parameters: ecs_params
          }
        end

        # Target with retry policy
        def self.reliable_target(rule:, target_id:, arn:, role_arn: nil, 
                               max_retry_attempts: 3, max_event_age_hours: 24)
          {
            rule: rule,
            target_id: target_id,
            arn: arn,
            role_arn: role_arn,
            retry_policy: {
              maximum_retry_attempts: max_retry_attempts,
              maximum_event_age_in_seconds: max_event_age_hours * 3600
            }
          }.compact
        end

        # Target with dead letter queue
        def self.target_with_dlq(rule:, target_id:, arn:, dlq_arn:, role_arn: nil)
          {
            rule: rule,
            target_id: target_id,
            arn: arn,
            role_arn: role_arn,
            dead_letter_config: { arn: dlq_arn }
          }.compact
        end

        # Target with input transformation
        def self.transformed_target(rule:, target_id:, arn:, input_template:, 
                                   input_paths: nil, role_arn: nil)
          transformer = { input_template: input_template }
          transformer[:input_paths] = input_paths if input_paths
          
          {
            rule: rule,
            target_id: target_id,
            arn: arn,
            role_arn: role_arn,
            input_transformer: transformer
          }.compact
        end

        # Batch job target
        def self.batch_target(rule:, target_id:, job_queue_arn:, job_definition:, 
                             job_name:, role_arn:, array_size: nil)
          batch_params = {
            job_definition: job_definition,
            job_name: job_name
          }
          
          if array_size
            batch_params[:array_properties] = { size: array_size }
          end
          
          {
            rule: rule,
            target_id: target_id,
            arn: job_queue_arn,
            role_arn: role_arn,
            batch_parameters: batch_params
          }
        end
      end
    end
      end
    end
  end
end