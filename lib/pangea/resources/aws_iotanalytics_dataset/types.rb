# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    # AWS IoT Analytics Dataset Types
    # 
    # Datasets provide a way to retrieve and analyze data from IoT Analytics datastores.
    # They enable SQL queries against time-series IoT data and support scheduled content generation.
    module AwsIotanalyticsDatasetTypes
      # Action configuration for dataset content generation
      class Action < Dry::Struct
        schema schema.strict

        # Name of the action
        attribute :action_name, Resources::Types::String

        # SQL query to execute for data retrieval
        class QueryAction < Dry::Struct
          schema schema.strict

          # SQL query string
          attribute :sql_query, Resources::Types::String

          # Filter configuration for query results
          class Filter < Dry::Struct
            schema schema.strict

            # Delta time filter for incremental processing
            class DeltaTime < Dry::Struct
              schema schema.strict

              # Offset in seconds from current time
              attribute :offset_seconds, Resources::Types::Integer

              # Time expression for filtering
              attribute :time_expression, Resources::Types::String
            end

            attribute? :delta_time, DeltaTime.optional
          end

          attribute :filters, Resources::Types::Array.of(Filter).optional
        end

        attribute? :query_action, QueryAction.optional

        # Container action for custom data processing
        class ContainerAction < Dry::Struct
          schema schema.strict

          # Docker image URI for processing
          attribute :image, Resources::Types::String

          # Execution role ARN
          attribute :execution_role_arn, Resources::Types::String

          # Resource configuration
          class ResourceConfiguration < Dry::Struct
            schema schema.strict

            # Compute type for processing
            attribute :compute_type, Resources::Types::String.enum('ACU_1', 'ACU_2')

            # Volume size in GB
            attribute :volume_size_in_gb, Resources::Types::Integer.constrained(gteq: 1, lteq: 50)
          end

          attribute :resource_configuration, ResourceConfiguration

          # Environment variables for container
          attribute :variables, Resources::Types::Hash.map(Types::String, Types::String).optional
        end

        attribute? :container_action, ContainerAction.optional
      end

      # Content delivery rules for dataset output
      class ContentDeliveryRule < Dry::Struct
        schema schema.strict

        # Entry name for the rule
        attribute :entry_name, Resources::Types::String

        # S3 destination configuration
        class Destination < Dry::Struct
          schema schema.strict

          class S3DestinationConfiguration < Dry::Struct
            schema schema.strict

            # S3 bucket name
            attribute :bucket, Resources::Types::String

            # Object key prefix
            attribute :key, Resources::Types::String

            # Glue database configuration
            class GlueConfiguration < Dry::Struct
              schema schema.strict

              # Glue table name
              attribute :table_name, Resources::Types::String

              # Glue database name
              attribute :database_name, Resources::Types::String
            end

            attribute? :glue_configuration, GlueConfiguration.optional

            # IAM role ARN for S3 access
            attribute :role_arn, Resources::Types::String
          end

          attribute? :s3_destination_configuration, S3DestinationConfiguration.optional
        end

        attribute :destination, Destination
      end

      # Trigger configuration for dataset content generation
      class Trigger < Dry::Struct
        schema schema.strict

        # Schedule trigger configuration
        class Schedule < Dry::Struct
          schema schema.strict

          # Schedule expression (cron or rate)
          attribute :schedule_expression, Resources::Types::String
        end

        attribute? :schedule, Schedule.optional

        # Triggering dataset configuration
        class TriggeringDataset < Dry::Struct
          schema schema.strict

          # Name of triggering dataset
          attribute :name, Resources::Types::String
        end

        attribute? :triggering_dataset, TriggeringDataset.optional
      end

      # Main attributes for IoT Analytics dataset resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the dataset
        attribute :dataset_name, Resources::Types::String

        # List of actions for dataset content generation
        attribute :actions, Resources::Types::Array.of(Action)

        # Content delivery rules
        attribute :content_delivery_rules, Resources::Types::Array.of(ContentDeliveryRule).optional

        # Triggers for dataset content generation
        attribute :triggers, Resources::Types::Array.of(Trigger).optional

        # Optional data retention period
        class RetentionPeriod < Dry::Struct
          schema schema.strict

          # Whether retention is unlimited
          attribute :unlimited, Resources::Types::Bool.optional

          # Number of days to retain (if not unlimited)
          attribute :number_of_days, Resources::Types::Integer.optional
        end

        attribute? :retention_period, RetentionPeriod.optional

        # Versioning configuration
        class VersioningConfiguration < Dry::Struct
          schema schema.strict

          # Whether versioning is unlimited
          attribute :unlimited, Resources::Types::Bool.optional

          # Maximum number of versions to keep
          attribute :max_versions, Resources::Types::Integer.optional
        end

        attribute? :versioning_configuration, VersioningConfiguration.optional

        # Resource tags
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from dataset resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The dataset ARN
        attribute :arn, Resources::Types::String

        # The dataset name
        attribute :name, Resources::Types::String
      end
    end
  end
end