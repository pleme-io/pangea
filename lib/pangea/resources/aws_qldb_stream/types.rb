# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS QLDB Stream resources
      class QldbStreamAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Stream name (required)
        attribute :stream_name, Resources::Types::String

        # Ledger name (required)
        attribute :ledger_name, Resources::Types::String

        # Role ARN for stream to assume (required)
        attribute :role_arn, Resources::Types::String

        # Kinesis configuration (required)
        attribute :kinesis_configuration, Resources::Types::Hash.schema(
          stream_arn: Resources::Types::String,
          aggregation_enabled?: Resources::Types::Bool.default(true)
        )

        # Inclusive start time (required)
        attribute :inclusive_start_time, Resources::Types::String

        # Exclusive end time (optional)
        attribute? :exclusive_end_time, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate stream name
          unless attrs.stream_name.match?(/\A[a-zA-Z0-9_-]+\z/)
            raise Dry::Struct::Error, "stream_name must contain only alphanumeric characters, underscores, and hyphens"
          end

          if attrs.stream_name.length < 1 || attrs.stream_name.length > 64
            raise Dry::Struct::Error, "stream_name must be between 1 and 64 characters"
          end

          # Validate ledger name
          unless attrs.ledger_name.match?(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/)
            raise Dry::Struct::Error, "ledger_name must start with a letter and contain only alphanumeric characters, underscores, and hyphens"
          end

          # Validate role ARN
          unless attrs.role_arn.match?(/\Aarn:aws[a-z\-]*:iam::\d{12}:role\/[\w+=,.@-]+\z/)
            raise Dry::Struct::Error, "role_arn must be a valid IAM role ARN"
          end

          # Validate Kinesis stream ARN
          unless attrs.kinesis_configuration[:stream_arn].match?(/\Aarn:aws[a-z\-]*:kinesis:[a-z0-9\-]+:\d{12}:stream\/[\w-]+\z/)
            raise Dry::Struct::Error, "kinesis stream_arn must be a valid Kinesis stream ARN"
          end

          # Validate timestamps
          validate_timestamps(attrs)

          attrs
        end

        def self.validate_timestamps(attrs)
          # Parse timestamps to ensure they're valid ISO 8601
          begin
            start_time = Time.parse(attrs.inclusive_start_time)
          rescue ArgumentError
            raise Dry::Struct::Error, "inclusive_start_time must be a valid ISO 8601 timestamp"
          end

          if attrs.exclusive_end_time
            begin
              end_time = Time.parse(attrs.exclusive_end_time)
            rescue ArgumentError
              raise Dry::Struct::Error, "exclusive_end_time must be a valid ISO 8601 timestamp"
            end

            if end_time <= start_time
              raise Dry::Struct::Error, "exclusive_end_time must be after inclusive_start_time"
            end
          end
        end

        # Helper methods
        def kinesis_stream_arn
          kinesis_configuration[:stream_arn]
        end

        def aggregation_enabled?
          kinesis_configuration[:aggregation_enabled]
        end

        def is_continuous_stream?
          exclusive_end_time.nil?
        end

        def is_bounded_stream?
          !exclusive_end_time.nil?
        end

        def stream_duration
          return nil if is_continuous_stream?
          
          start_time = Time.parse(inclusive_start_time)
          end_time = Time.parse(exclusive_end_time)
          end_time - start_time
        end

        def stream_type
          is_continuous_stream? ? :continuous : :bounded
        end

        def estimated_monthly_cost
          # Base streaming cost
          base_cost = 0.03 # $0.03 per GB of journal data streamed
          
          # Estimate based on typical QLDB usage
          estimated_gb_per_month = 10.0 # Conservative estimate
          
          streaming_cost = estimated_gb_per_month * base_cost
          
          # Add Kinesis costs (simplified)
          kinesis_cost = 0.015 * 730 # $0.015 per hour for Kinesis shard
          
          streaming_cost + kinesis_cost
        end

        def stream_features
          features = [:real_time_streaming, :journal_export]
          features << :record_aggregation if aggregation_enabled?
          features << :continuous_streaming if is_continuous_stream?
          features << :bounded_export if is_bounded_stream?
          features
        end

        def use_cases
          cases = []
          
          if is_continuous_stream?
            cases.concat([
              :real_time_analytics,
              :event_driven_processing,
              :data_lake_ingestion,
              :cross_region_replication
            ])
          else
            cases.concat([
              :point_in_time_export,
              :audit_log_extraction,
              :compliance_reporting,
              :data_migration
            ])
          end
          
          cases
        end

        def kinesis_region
          kinesis_stream_arn.split(':')[3]
        end

        def role_account_id
          role_arn.split(':')[4]
        end

        def required_iam_permissions
          [
            'kinesis:PutRecords',
            'kinesis:PutRecord',
            'kinesis:DescribeStream',
            'kinesis:ListShards'
          ]
        end

        def stream_record_format
          {
            qldbStreamArn: 'Stream ARN',
            recordType: 'BLOCK_SUMMARY or REVISION_DETAILS',
            payload: {
              blockAddress: 'Block location in journal',
              transactionId: 'Transaction identifier',
              blockTimestamp: 'Block creation time',
              blockHash: 'SHA-256 hash of block',
              entriesHash: 'Hash of block entries',
              previousBlockHash: 'Previous block hash',
              entriesHashList: 'List of entry hashes',
              transactionInfo: 'Transaction metadata',
              revisionSummaries: 'Document revision details'
            }
          }
        end
      end
    end
      end
    end
  end
end