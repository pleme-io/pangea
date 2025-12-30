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

module Pangea
  module Resources
    module AWS
      module Types
        # Shared schema definitions for Kinesis Firehose Delivery Stream
        module FirehoseSharedSchemas
          include Dry.Types()

          # CloudWatch logging options schema - reused across all destinations
          CloudWatchLoggingOptions = Dry.Types()['hash'].schema(
            enabled?: Dry.Types()['bool'].optional,
            log_group_name?: Dry.Types()['string'].optional,
            log_stream_name?: Dry.Types()['string'].optional
          )

          # Processing configuration schema - reused across multiple destinations
          ProcessingConfiguration = Dry.Types()['hash'].schema(
            enabled: Dry.Types()['bool'],
            processors?: Dry.Types()['array'].of(Dry.Types()['hash'].schema(
              type: Dry.Types()['string'].enum('Lambda'),
              parameters?: Dry.Types()['array'].of(Dry.Types()['hash'].schema(
                parameter_name: Dry.Types()['string'],
                parameter_value: Dry.Types()['string']
              )).optional
            )).optional
          )

          # KMS encryption configuration schema
          EncryptionConfiguration = Dry.Types()['hash'].schema(
            no_encryption_config?: Dry.Types()['string'].enum('NoEncryption').optional,
            kms_encryption_config?: Dry.Types()['hash'].schema(
              aws_kms_key_arn: Dry.Types()['string']
            ).optional
          )

          # Buffer size constraints (1-128 MB for S3)
          S3BufferSize = Dry.Types()['integer'].constrained(gteq: 1, lteq: 128)

          # Buffer interval constraints (60-900 seconds)
          BufferInterval = Dry.Types()['integer'].constrained(gteq: 60, lteq: 900)

          # Retry duration constraints (0-7200 seconds)
          RetryDuration = Dry.Types()['integer'].constrained(gteq: 0, lteq: 7200)

          # Compression formats for S3
          S3CompressionFormat = Dry.Types()['string'].enum(
            'UNCOMPRESSED', 'GZIP', 'ZIP', 'Snappy', 'HADOOP_SNAPPY'
          )

          # Index rotation periods for search destinations
          IndexRotationPeriod = Dry.Types()['string'].enum(
            'NoRotation', 'OneHour', 'OneDay', 'OneWeek', 'OneMonth'
          )

          # Search destination buffer size (1-100 MB)
          SearchBufferSize = Dry.Types()['integer'].constrained(gteq: 1, lteq: 100)

          # HTTP endpoint buffer size (1-64 MB)
          HttpBufferSize = Dry.Types()['integer'].constrained(gteq: 1, lteq: 64)
        end
      end
    end
  end
end
