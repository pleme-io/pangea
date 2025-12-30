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

require_relative 'shared_schemas'

module Pangea
  module Resources
    module AWS
      module Types
        # S3 destination schemas for Kinesis Firehose Delivery Stream
        module FirehoseS3Destinations
          include FirehoseSharedSchemas

          # Basic S3 destination configuration
          S3Configuration = Hash.schema(
            role_arn: String,
            bucket_arn: String,
            prefix?: String.optional,
            error_output_prefix?: String.optional,
            buffer_size?: FirehoseSharedSchemas::S3BufferSize.optional,
            buffer_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            compression_format?: FirehoseSharedSchemas::S3CompressionFormat.optional,
            encryption_configuration?: FirehoseSharedSchemas::EncryptionConfiguration.optional,
            cloudwatch_logging_options?: FirehoseSharedSchemas::CloudWatchLoggingOptions.optional
          )

          # Data format conversion configuration for Extended S3
          DataFormatConversionConfiguration = Hash.schema(
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
          )

          # Extended S3 destination configuration
          ExtendedS3Configuration = Hash.schema(
            role_arn: String,
            bucket_arn: String,
            prefix?: String.optional,
            error_output_prefix?: String.optional,
            buffer_size?: FirehoseSharedSchemas::S3BufferSize.optional,
            buffer_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            compression_format?: FirehoseSharedSchemas::S3CompressionFormat.optional,
            data_format_conversion_configuration?: DataFormatConversionConfiguration.optional,
            processing_configuration?: FirehoseSharedSchemas::ProcessingConfiguration.optional,
            cloudwatch_logging_options?: FirehoseSharedSchemas::CloudWatchLoggingOptions.optional,
            s3_backup_mode?: String.enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: Hash.optional
          )
        end
      end
    end
  end
end
