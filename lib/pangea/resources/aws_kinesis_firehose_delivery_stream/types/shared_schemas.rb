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

module Pangea
  module Resources
    module AWS
      module Types
        # Shared schema definitions for Kinesis Firehose Delivery Stream
        module FirehoseSharedSchemas
          # CloudWatch logging options schema - reused across all destinations
          CloudWatchLoggingOptions = Hash.schema(
            enabled?: Bool.optional,
            log_group_name?: String.optional,
            log_stream_name?: String.optional
          )

          # Processing configuration schema - reused across multiple destinations
          ProcessingConfiguration = Hash.schema(
            enabled: Bool,
            processors?: Array.of(Hash.schema(
              type: String.enum('Lambda'),
              parameters?: Array.of(Hash.schema(
                parameter_name: String,
                parameter_value: String
              )).optional
            )).optional
          )

          # KMS encryption configuration schema
          EncryptionConfiguration = Hash.schema(
            no_encryption_config?: String.enum('NoEncryption').optional,
            kms_encryption_config?: Hash.schema(
              aws_kms_key_arn: String
            ).optional
          )

          # Buffer size constraints (1-128 MB for S3)
          S3BufferSize = Integer.constrained(gteq: 1, lteq: 128)

          # Buffer interval constraints (60-900 seconds)
          BufferInterval = Integer.constrained(gteq: 60, lteq: 900)

          # Retry duration constraints (0-7200 seconds)
          RetryDuration = Integer.constrained(gteq: 0, lteq: 7200)

          # Compression formats for S3
          S3CompressionFormat = String.enum(
            'UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY'
          )

          # Index rotation periods for search destinations
          IndexRotationPeriod = String.enum(
            'NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth'
          )

          # Search destination buffer size (1-100 MB)
          SearchBufferSize = Integer.constrained(gteq: 1, lteq: 100)

          # HTTP endpoint buffer size (1-64 MB)
          HttpBufferSize = Integer.constrained(gteq: 1, lteq: 64)
        end
      end
    end
  end
end
