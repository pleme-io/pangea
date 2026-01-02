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
require_relative 'types/validation'
require_relative 'types/computed_properties'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Firehose Delivery Stream resource attributes with validation
        class KinesisFirehoseDeliveryStreamAttributes < Dry::Struct
          include FirehoseComputedProperties
          transform_keys(&:to_sym)

          T = Resources::Types

          attribute :name, T::String
          attribute :destination, T::String.enum(
            'extended_s3', 's3', 'redshift', 'elasticsearch', 'amazonopensearch',
            'splunk', 'http_endpoint', 'snowflake'
          )

          # S3 destination configuration
          attribute :s3_configuration, T::Hash.schema(
            role_arn: T::String, bucket_arn: T::String,
            prefix?: T::String.optional, error_output_prefix?: T::String.optional,
            buffer_size?: T::Integer.constrained(gteq: 1, lteq: 128).optional,
            buffer_interval?: T::Integer.constrained(gteq: 60, lteq: 900).optional,
            compression_format?: T::String.enum(
              'UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY'
            ).optional,
            encryption_configuration?: T::Hash.schema(
              no_encryption_config?: T::String.enum('NoEncryption').optional,
              kms_encryption_config?: T::Hash.schema(aws_kms_key_arn: T::String).optional
            ).optional,
            cloudwatch_logging_options?: T::Hash.schema(
              enabled?: T::Bool.optional, log_group_name?: T::String.optional,
              log_stream_name?: T::String.optional
            ).optional
          ).optional

          # Extended S3 destination configuration
          attribute :extended_s3_configuration, T::Hash.schema(
            role_arn: T::String, bucket_arn: T::String,
            prefix?: T::String.optional, error_output_prefix?: T::String.optional,
            buffer_size?: T::Integer.constrained(gteq: 1, lteq: 128).optional,
            buffer_interval?: T::Integer.constrained(gteq: 60, lteq: 900).optional,
            compression_format?: T::String.enum(
              'UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY'
            ).optional,
            data_format_conversion_configuration?: T::Hash.schema(
              enabled: T::Bool,
              output_format_configuration?: T::Hash.schema(
                serializer?: T::Hash.schema(
                  parquet_ser_de?: T::Hash.optional, orc_ser_de?: T::Hash.optional
                ).optional
              ).optional,
              schema_configuration?: T::Hash.schema(
                database_name: T::String, table_name: T::String, role_arn: T::String,
                region?: T::String.optional, catalog_id?: T::String.optional,
                version_id?: T::String.optional
              ).optional
            ).optional,
            processing_configuration?: T::Hash.schema(
              enabled: T::Bool,
              processors?: T::Array.of(T::Hash.schema(
                type: T::String.enum('Lambda'),
                parameters?: T::Array.of(T::Hash.schema(
                  parameter_name: T::String, parameter_value: T::String
                )).optional
              )).optional
            ).optional,
            cloudwatch_logging_options?: T::Hash.schema(
              enabled?: T::Bool.optional, log_group_name?: T::String.optional,
              log_stream_name?: T::String.optional
            ).optional,
            s3_backup_mode?: T::String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: T::Hash.optional
          ).optional

          # Redshift destination configuration
          attribute :redshift_configuration, T::Hash.schema(
            role_arn: T::String, cluster_jdbcurl: T::String, username: T::String,
            password: T::String, data_table_name: T::String,
            copy_options?: T::String.optional, data_table_columns?: T::String.optional,
            s3_backup_mode?: T::String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: T::Hash.optional, processing_configuration?: T::Hash.optional,
            cloudwatch_logging_options?: T::Hash.optional
          ).optional

          # Elasticsearch destination configuration
          attribute :elasticsearch_configuration, T::Hash.schema(
            role_arn: T::String, domain_arn: T::String, index_name: T::String,
            type_name?: T::String.optional,
            index_rotation_period?: T::String.enum(
              'NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth'
            ).optional,
            buffering_size?: T::Integer.constrained(gteq: 1, lteq: 100).optional,
            buffering_interval?: T::Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: T::Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: T::String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: T::Hash.optional, cloudwatch_logging_options?: T::Hash.optional
          ).optional

          # OpenSearch destination configuration
          attribute :amazonopensearch_configuration, T::Hash.schema(
            role_arn: T::String, domain_arn: T::String, index_name: T::String,
            type_name?: T::String.optional,
            index_rotation_period?: T::String.enum(
              'NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth'
            ).optional,
            buffering_size?: T::Integer.constrained(gteq: 1, lteq: 100).optional,
            buffering_interval?: T::Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: T::Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: T::String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: T::Hash.optional, cloudwatch_logging_options?: T::Hash.optional
          ).optional

          # Splunk destination configuration
          attribute :splunk_configuration, T::Hash.schema(
            hec_endpoint: T::String, hec_token: T::String,
            hec_acknowledgment_timeout?: T::Integer.constrained(gteq: 180, lteq: 600).optional,
            hec_endpoint_type?: T::String.enum('Raw', 'Event').optional,
            retry_duration?: T::Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: T::String.enum('FailedEventsOnly', 'AllEvents').optional,
            processing_configuration?: T::Hash.optional, cloudwatch_logging_options?: T::Hash.optional
          ).optional

          # HTTP endpoint destination configuration
          attribute :http_endpoint_configuration, T::Hash.schema(
            url: T::String, name?: T::String.optional, access_key?: T::String.optional,
            buffering_size?: T::Integer.constrained(gteq: 1, lteq: 64).optional,
            buffering_interval?: T::Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: T::Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: T::String.enum('FailedDataOnly', 'AllData').optional,
            request_configuration?: T::Hash.schema(
              content_encoding?: T::String.enum('NONE', 'GZIP').optional,
              common_attributes?: T::Hash.map(T::String, T::String).optional
            ).optional,
            processing_configuration?: T::Hash.optional, cloudwatch_logging_options?: T::Hash.optional
          ).optional

          # Kinesis source configuration
          attribute :kinesis_source_configuration, T::Hash.schema(
            kinesis_stream_arn: T::String, role_arn: T::String
          ).optional

          # Server-side encryption
          attribute :server_side_encryption, T::Hash.schema(
            enabled?: T::Bool.default(false),
            key_type?: T::String.enum('AWS_OWNED_CMK', 'CUSTOMER_MANAGED_CMK').optional,
            key_arn?: T::String.optional
          ).optional

          attribute :tags, T::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(::Hash) ? attributes : {}
            FirehoseValidation.validate_destination_config!(attrs)
            FirehoseValidation.validate_encryption_config!(attrs)
            FirehoseValidation.validate_source_arns!(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
