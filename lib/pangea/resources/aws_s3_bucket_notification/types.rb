# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket Notification Configuration resources
      class S3BucketNotificationAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # The name of the bucket to configure notifications for
        attribute :bucket, Resources::Types::String

        # CloudWatch topic configuration for object creation events
        attribute :cloudwatch_configuration, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            topic_arn: Resources::Types::String,
            events: Resources::Types::Array.of(
              Resources::Types::String.enum(
                's3:ObjectCreated:*',
                's3:ObjectCreated:Put',
                's3:ObjectCreated:Post',
                's3:ObjectCreated:Copy',
                's3:ObjectCreated:CompleteMultipartUpload',
                's3:ObjectRemoved:*',
                's3:ObjectRemoved:Delete',
                's3:ObjectRemoved:DeleteMarkerCreated',
                's3:ObjectRestore:*',
                's3:ObjectRestore:Post',
                's3:ObjectRestore:Completed',
                's3:Replication:*',
                's3:Replication:OperationFailedReplication',
                's3:Replication:OperationNotTracked',
                's3:Replication:OperationMissedThreshold',
                's3:Replication:OperationReplicatedAfterThreshold'
              )
            ),
            filter_prefix?: Resources::Types::String.optional,
            filter_suffix?: Resources::Types::String.optional
          )
        ).default([])

        # Lambda function configurations for event processing
        attribute :lambda_function, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            lambda_function_arn: Resources::Types::String,
            events: Resources::Types::Array.of(
              Resources::Types::String.enum(
                's3:ObjectCreated:*',
                's3:ObjectCreated:Put',
                's3:ObjectCreated:Post',
                's3:ObjectCreated:Copy',
                's3:ObjectCreated:CompleteMultipartUpload',
                's3:ObjectRemoved:*',
                's3:ObjectRemoved:Delete',
                's3:ObjectRemoved:DeleteMarkerCreated',
                's3:ObjectRestore:*',
                's3:ObjectRestore:Post',
                's3:ObjectRestore:Completed',
                's3:Replication:*',
                's3:Replication:OperationFailedReplication',
                's3:Replication:OperationNotTracked',
                's3:Replication:OperationMissedThreshold',
                's3:Replication:OperationReplicatedAfterThreshold'
              )
            ),
            filter_prefix?: Resources::Types::String.optional,
            filter_suffix?: Resources::Types::String.optional
          )
        ).default([])

        # SQS queue configurations for event queuing
        attribute :queue, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            id?: Resources::Types::String.optional,
            queue_arn: Resources::Types::String,
            events: Resources::Types::Array.of(
              Resources::Types::String.enum(
                's3:ObjectCreated:*',
                's3:ObjectCreated:Put',
                's3:ObjectCreated:Post',
                's3:ObjectCreated:Copy',
                's3:ObjectCreated:CompleteMultipartUpload',
                's3:ObjectRemoved:*',
                's3:ObjectRemoved:Delete',
                's3:ObjectRemoved:DeleteMarkerCreated',
                's3:ObjectRestore:*',
                's3:ObjectRestore:Post',
                's3:ObjectRestore:Completed',
                's3:Replication:*',
                's3:Replication:OperationFailedReplication',
                's3:Replication:OperationNotTracked',
                's3:Replication:OperationMissedThreshold',
                's3:Replication:OperationReplicatedAfterThreshold'
              )
            ),
            filter_prefix?: Resources::Types::String.optional,
            filter_suffix?: Resources::Types::String.optional
          )
        ).default([])

        # EventBridge configuration for advanced event routing
        attribute :eventbridge, Resources::Types::Bool.default(false)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate at least one notification configuration exists
          total_configurations = attrs.cloudwatch_configuration.size + 
                               attrs.lambda_function.size + 
                               attrs.queue.size + 
                               (attrs.eventbridge ? 1 : 0)

          if total_configurations == 0
            raise Dry::Struct::Error, "At least one notification configuration (cloudwatch, lambda, queue, or eventbridge) must be specified"
          end

          # Validate ARN formats
          validate_arn_format(attrs.cloudwatch_configuration, 'topic_arn', 'sns')
          validate_arn_format(attrs.lambda_function, 'lambda_function_arn', 'lambda')
          validate_arn_format(attrs.queue, 'queue_arn', 'sqs')

          # Validate filter combinations
          validate_filters(attrs.cloudwatch_configuration)
          validate_filters(attrs.lambda_function)
          validate_filters(attrs.queue)

          attrs
        end

        private

        def self.validate_arn_format(configurations, arn_key, expected_service)
          configurations.each do |config|
            arn = config[arn_key]
            unless arn.start_with?("arn:aws:#{expected_service}:")
              raise Dry::Struct::Error, "#{arn_key} must be a valid #{expected_service.upcase} ARN"
            end
          end
        end

        def self.validate_filters(configurations)
          configurations.each do |config|
            if config[:filter_prefix] && config[:filter_suffix]
              # Both prefix and suffix filters are allowed, no validation needed
              next
            end
          end
        end

        # Helper methods
        def total_notification_destinations
          cloudwatch_configuration.size + lambda_function.size + queue.size + (eventbridge ? 1 : 0)
        end

        def has_lambda_notifications?
          lambda_function.any?
        end

        def has_sqs_notifications?
          queue.any?
        end

        def has_sns_notifications?
          cloudwatch_configuration.any?
        end

        def has_eventbridge_enabled?
          eventbridge
        end

        def all_configured_events
          events = []
          events.concat(cloudwatch_configuration.flat_map { |config| config[:events] })
          events.concat(lambda_function.flat_map { |config| config[:events] })
          events.concat(queue.flat_map { |config| config[:events] })
          events.uniq
        end

        def uses_wildcard_events?
          all_configured_events.any? { |event| event.include?('*') }
        end

        def monitors_object_creation?
          all_configured_events.any? { |event| event.include?('ObjectCreated') }
        end

        def monitors_object_removal?
          all_configured_events.any? { |event| event.include?('ObjectRemoved') }
        end

        def monitors_object_restore?
          all_configured_events.any? { |event| event.include?('ObjectRestore') }
        end

        def monitors_replication?
          all_configured_events.any? { |event| event.include?('Replication') }
        end
      end
    end
      end
    end
  end
end