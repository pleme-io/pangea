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
        # Kinesis Firehose Delivery Stream resource attributes with validation
        class KinesisFirehoseDeliveryStreamAttributes < Dry::Struct
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
            compression_format?: String.enum('UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY').optional,
            encryption_configuration?: Hash.schema(
              no_encryption_config?: String.enum('NoEncryption').optional,
              kms_encryption_config?: Hash.schema(
                aws_kms_key_arn: String
              ).optional
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
            compression_format?: String.enum('UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY').optional,
            data_format_conversion_configuration?: Hash.schema(
              enabled: Bool,
              output_format_configuration?: Hash.schema(
                serializer?: Hash.schema(
                  parquet_ser_de?: Hash.optional,
                  orc_ser_de?: Hash.optional
                ).optional
              ).optional,
              schema_configuration?: Hash.schema(
                database_name: String,
                table_name: String,
                role_arn: String,
                region?: String.optional,
                catalog_id?: String.optional,
                version_id?: String.optional
              ).optional
            ).optional,
            processing_configuration?: Hash.schema(
              enabled: Bool,
              processors?: Array.of(Hash.schema(
                type: String.enum('Lambda'),
                parameters?: Array.of(Hash.schema(
                  parameter_name: String,
                  parameter_value: String
                )).optional
              )).optional
            ).optional,
            cloudwatch_logging_options?: Hash.schema(
              enabled?: Bool.optional,
              log_group_name?: String.optional,
              log_stream_name?: String.optional
            ).optional,
            s3_backup_mode?: String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: Hash.optional
          ).optional
          
          # Redshift destination configuration
          attribute :redshift_configuration, Hash.schema(
            role_arn: String,
            cluster_jdbcurl: String,
            username: String,
            password: String,
            data_table_name: String,
            copy_options?: String.optional,
            data_table_columns?: String.optional,
            s3_backup_mode?: String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: Hash.optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          ).optional
          
          # Elasticsearch destination configuration
          attribute :elasticsearch_configuration, Hash.schema(
            role_arn: String,
            domain_arn: String,
            index_name: String,
            type_name?: String.optional,
            index_rotation_period?: String.enum('NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth').optional,
            buffering_size?: Integer.constrained(gteq: 1, lteq: 100).optional,
            buffering_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          ).optional
          
          # OpenSearch destination configuration  
          attribute :amazonopensearch_configuration, Hash.schema(
            role_arn: String,
            domain_arn: String,
            index_name: String,
            type_name?: String.optional,
            index_rotation_period?: String.enum('NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth').optional,
            buffering_size?: Integer.constrained(gteq: 1, lteq: 100).optional,
            buffering_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          ).optional
          
          # Splunk destination configuration
          attribute :splunk_configuration, Hash.schema(
            hec_endpoint: String,
            hec_token: String,
            hec_acknowledgment_timeout?: Integer.constrained(gteq: 180, lteq: 600).optional,
            hec_endpoint_type?: String.enum('Raw', 'Event').optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedEventsOnly', 'AllEvents').optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          ).optional
          
          # HTTP endpoint destination configuration
          attribute :http_endpoint_configuration, Hash.schema(
            url: String,
            name?: String.optional,
            access_key?: String.optional,
            buffering_size?: Integer.constrained(gteq: 1, lteq: 64).optional,
            buffering_interval?: Integer.constrained(gteq: 60, lteq: 900).optional,
            retry_duration?: Integer.constrained(gteq: 0, lteq: 7200).optional,
            s3_backup_mode?: String.enum('FailedDataOnly', 'AllData').optional,
            request_configuration?: Hash.schema(
              content_encoding?: String.enum('NONE', 'GZIP').optional,
              common_attributes?: Hash.map(String, String).optional
            ).optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          ).optional
          
          # Kinesis source configuration
          attribute :kinesis_source_configuration, Hash.schema(
            kinesis_stream_arn: String,
            role_arn: String
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
            
            # Validate destination configuration is provided
            destination_configs = [
              :s3_configuration, :extended_s3_configuration, :redshift_configuration,
              :elasticsearch_configuration, :amazonopensearch_configuration,
              :splunk_configuration, :http_endpoint_configuration
            ]
            
            destination = attrs[:destination]
            config_key = case destination
                        when 's3' then :s3_configuration
                        when 'extended_s3' then :extended_s3_configuration
                        when 'redshift' then :redshift_configuration
                        when 'elasticsearch' then :elasticsearch_configuration
                        when 'amazonopensearch' then :amazonopensearch_configuration
                        when 'splunk' then :splunk_configuration
                        when 'http_endpoint' then :http_endpoint_configuration
                        end
            
            if config_key && !attrs[config_key]
              raise Dry::Struct::Error, "#{config_key} is required when destination is '#{destination}'"
            end
            
            # Validate encryption configuration for server-side encryption
            if attrs[:server_side_encryption] && attrs[:server_side_encryption][:enabled]
              sse_config = attrs[:server_side_encryption]
              if sse_config[:key_type] == 'CUSTOMER_MANAGED_CMK' && !sse_config[:key_arn]
                raise Dry::Struct::Error, "key_arn is required when key_type is 'CUSTOMER_MANAGED_CMK'"
              end
            end
            
            # Validate ARN formats
            if attrs[:kinesis_source_configuration]
              validate_arn!(attrs[:kinesis_source_configuration][:kinesis_stream_arn], 'kinesis')
              validate_arn!(attrs[:kinesis_source_configuration][:role_arn], 'iam')
            end
            
            super(attrs)
          end
          
          # ARN validation helper
          def self.validate_arn!(arn, service)
            pattern = case service
                     when 'kinesis' then /\Aarn:aws:kinesis:[a-z0-9-]+:\d{12}:stream\/[a-zA-Z0-9_-]+\z/
                     when 'iam' then /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_\+\=\,\.\@\-]+\z/
                     when 's3' then /\Aarn:aws:s3:::[a-z0-9.-]+\z/
                     else /\Aarn:aws:[a-z0-9-]+:[a-z0-9-]*:\d{12}:.+\z/
                     end
            
            unless arn.match?(pattern)
              raise Dry::Struct::Error, "Invalid #{service} ARN format: #{arn}"
            end
          end
          
          # Computed properties
          def has_data_transformation?
            case destination
            when 'extended_s3'
              extended_s3_configuration&.dig(:processing_configuration, :enabled) == true
            when 'redshift', 'elasticsearch', 'amazonopensearch', 'splunk', 'http_endpoint'
              config = public_send("#{destination}_configuration".to_sym)
              config&.dig(:processing_configuration, :enabled) == true
            else
              false
            end
          end
          
          def has_format_conversion?
            destination == 'extended_s3' && 
              extended_s3_configuration&.dig(:data_format_conversion_configuration, :enabled) == true
          end
          
          def backup_enabled?
            case destination
            when 'extended_s3'
              extended_s3_configuration&.dig(:s3_backup_mode) == 'Enabled'
            when 'redshift'
              redshift_configuration&.dig(:s3_backup_mode) == 'Enabled'
            when 'elasticsearch'
              elasticsearch_configuration&.dig(:s3_backup_mode) == 'AllDocuments'
            when 'amazonopensearch'
              amazonopensearch_configuration&.dig(:s3_backup_mode) == 'AllDocuments'
            when 'splunk'
              splunk_configuration&.dig(:s3_backup_mode) == 'AllEvents'
            when 'http_endpoint'
              http_endpoint_configuration&.dig(:s3_backup_mode) == 'AllData'
            else
              false
            end
          end
          
          def is_encrypted?
            server_side_encryption&.dig(:enabled) == true
          end
          
          def uses_customer_managed_key?
            is_encrypted? && server_side_encryption&.dig(:key_type) == 'CUSTOMER_MANAGED_CMK'
          end
          
          def has_kinesis_source?
            !kinesis_source_configuration.nil?
          end
          
          def estimated_monthly_cost_usd
            # Base Firehose pricing: $0.029 per GB ingested
            # Plus destination-specific costs and data transformation costs
            "Variable - depends on data volume and destination"
          end
        end
      end
    end
  end
end