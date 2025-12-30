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

          attribute :name, String
          attribute :destination, String.enum(
            'extended_s3', 's3', 'redshift', 'elasticsearch', 'amazonopensearch',
            'splunk', 'http_endpoint', 'snowflake'
          )

          # S3 destination configuration
          attribute :s3_configuration, Hash.schema(
            role_arn: String,
            bucket_arn: String,
            prefix?: String.optional,
            error_output_prefix?: String.optional,
            buffer_size?: Integer.constrained(gteq: 1, lteq: 128).optional,
            buffer_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            compression_format?: String.enum(
              'UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY'
            ).optional,
            encryption_configuration?: Hash.schema(
              no_encryption_config?: String.enum('NoEncryption').optional,
              kms_encryption_config?: Hash.schema(aws_kms_key_arn: String).optional
            ).optional,
            cloudwatch_logging_options?: Hash.schema(
              enabled?: Bool.optional,
              log_group_name?: String.optional,
              log_stream_name?: String.optional
            ).optional
          ).optional

          # Extended S3 destination configuration
          attribute :extended_s3_configuration, Hash.schema(
            role_arn: String,
            bucket_arn: String,
            prefix?: String.optional,
            error_output_prefix?: String.optional,
            buffer_size?: Integer.constrained(gteq: 1, lteq: 128).optional,
            buffer_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            compression_format?: String.enum(
              'UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY'
            ).optional,
            data_format_conversion_configuration?: Hash.schema(
              enabled: Bool,
              output_format_configuration?: Hash.schema(
                serializer?: Hash.schema(
                  parquet_ser_de?: Hash.optional, orc_ser_de?: Hash.optional
                ).optional
              ).optional,
              schema_configuration?: Hash.schema(
                database_name: String, table_name: String, role_arn: String,
                region?: String.optional, catalog_id?: String.optional, version_id?: String.optional
              ).optional
            ).optional,
            processing_configuration?: Hash.schema(
              enabled: Bool,
              processors?: Array.of(Hash.schema(
                type: String.enum('Lambda'),
                parameters?: Array.of(Hash.schema(
                  parameter_name: String, parameter_value: String
                )).optional
              )).optional
            ).optional,
            cloudwatch_logging_options?: Hash.schema(
              enabled?: Bool.optional, log_group_name?: String.optional, log_stream_name?: String.optional
            ).optional,
            s3_backup_mode?: String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: Hash.optional
          ).optional

          # Redshift destination configuration
          attribute :redshift_configuration, Hash.schema(
            role_arn: String, cluster_jdbcurl: String, username: String,
            password: String, data_table_name: String,
            copy_options?: String.optional, data_table_columns?: String.optional,
            s3_backup_mode?: String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: Hash.optional, processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          ).optional

          # Elasticsearch destination configuration
          attribute :elasticsearch_configuration, Hash.schema(
            role_arn: String, domain_arn: String, index_name: String,
            type_name?: String.optional,
            index_rotation_period?: String.enum(
              'NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth'
            ).optional,
            buffering_size?: Integer.constrained(gteq: 1, lteq: 100).optional,
            buffering_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: Hash.optional, cloudwatch_logging_options?: Hash.optional
          ).optional

          # OpenSearch destination configuration
          attribute :amazonopensearch_configuration, Hash.schema(
            role_arn: String, domain_arn: String, index_name: String,
            type_name?: String.optional,
            index_rotation_period?: String.enum(
              'NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth'
            ).optional,
            buffering_size?: Integer.constrained(gteq: 1, lteq: 100).optional,
            buffering_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: Hash.optional, cloudwatch_logging_options?: Hash.optional
          ).optional

          # Splunk destination configuration
          attribute :splunk_configuration, Hash.schema(
            hec_endpoint: String, hec_token: String,
            hec_acknowledgment_timeout?: Integer.constrained(gteq: 180, lteq: 600).optional,
            hec_endpoint_type?: String.enum('Raw', 'Event').optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedEventsOnly', 'AllEvents').optional,
            processing_configuration?: Hash.optional, cloudwatch_logging_options?: Hash.optional
          ).optional

          # HTTP endpoint destination configuration
          attribute :http_endpoint_configuration, Hash.schema(
            url: String, name?: String.optional, access_key?: String.optional,
            buffering_size?: Integer.constrained(gteq: 1, lteq: 64).optional,
            buffering_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedDataOnly', 'AllData').optional,
            request_configuration?: Hash.schema(
              content_encoding?: String.enum('NONE', 'GZIP').optional,
              common_attributes?: Hash.map(String, String).optional
            ).optional,
            processing_configuration?: Hash.optional, cloudwatch_logging_options?: Hash.optional
          ).optional

          # Kinesis source configuration
          attribute :kinesis_source_configuration, Hash.schema(
            kinesis_stream_arn: String, role_arn: String
          ).optional

          # Server-side encryption
          attribute :server_side_encryption, Hash.schema(
            enabled?: Bool.default(false),
            key_type?: String.enum('AWS_OWNED_CMK', 'CUSTOMER_MANAGED_CMK').optional,
            key_arn?: String.optional
          ).optional

          attribute :tags, Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
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
