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

require 'dry-types'
require_relative 'shared_schemas'

module Pangea
  module Resources
    module AWS
      module Types
        # S3 destination schemas for Kinesis Firehose Delivery Stream
        module FirehoseS3Destinations
          T = Dry.Types()

          # Basic S3 destination configuration
          S3Configuration = T['hash'].schema(
            role_arn: T['string'],
            bucket_arn: T['string'],
            prefix?: T['string'].optional,
            error_output_prefix?: T['string'].optional,
            buffer_size?: FirehoseSharedSchemas::S3BufferSize.optional,
            buffer_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            compression_format?: FirehoseSharedSchemas::S3CompressionFormat.optional,
            encryption_configuration?: FirehoseSharedSchemas::EncryptionConfiguration.optional,
            cloudwatch_logging_options?: FirehoseSharedSchemas::CloudWatchLoggingOptions.optional
          )

          # Data format conversion configuration for Extended S3
          DataFormatConversionConfiguration = T['hash'].schema(
            enabled: T['bool'],
            output_format_configuration?: T['hash'].schema(
              serializer?: T['hash'].schema(
                parquet_ser_de?: T['hash'].optional,
                orc_ser_de?: T['hash'].optional
              ).optional
            ).optional,
            schema_configuration?: T['hash'].schema(
              database_name: T['string'],
              table_name: T['string'],
              role_arn: T['string'],
              region?: T['string'].optional,
              catalog_id?: T['string'].optional,
              version_id?: T['string'].optional
            ).optional
          )

          # Extended S3 destination configuration
          ExtendedS3Configuration = T['hash'].schema(
            role_arn: T['string'],
            bucket_arn: T['string'],
            prefix?: T['string'].optional,
            error_output_prefix?: T['string'].optional,
            buffer_size?: FirehoseSharedSchemas::S3BufferSize.optional,
            buffer_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            compression_format?: FirehoseSharedSchemas::S3CompressionFormat.optional,
            data_format_conversion_configuration?: DataFormatConversionConfiguration.optional,
            processing_configuration?: FirehoseSharedSchemas::ProcessingConfiguration.optional,
            cloudwatch_logging_options?: FirehoseSharedSchemas::CloudWatchLoggingOptions.optional,
            s3_backup_mode?: T['string'].enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: T['hash'].optional
          )
        end
      end
    end
  end
end
