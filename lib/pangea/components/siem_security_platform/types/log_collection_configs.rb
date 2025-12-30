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
require 'pangea/components/types'

module Pangea
  module Components
    module SiemSecurityPlatform
      # Log source entry configuration
      class LogSourceEntry < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum(
          'cloudtrail', 'vpc_flow_logs', 'cloudwatch', 'waf', 's3_access', 'alb', 'custom'
        )
        attribute :source_arn, Types::String.optional
        attribute :log_group_name, Types::String.optional
        attribute :s3_bucket, Types::String.optional
        attribute :s3_prefix, Types::String.optional
        attribute :format, Types::String.enum('json', 'csv', 'syslog', 'cef', 'leef').default('json')
        attribute :transformation, Types::String.optional
        attribute :enrichment, Types::Bool.default(true)
      end

      # Kinesis Firehose configuration
      class FirehoseConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :buffer_size, Types::Integer.default(5).constrained(gteq: 1, lteq: 128)
        attribute :buffer_interval, Types::Integer.default(300).constrained(gteq: 60, lteq: 900)
        attribute :compression_format, Types::String.enum(
          'GZIP', 'SNAPPY', 'ZIP', 'UNCOMPRESSED'
        ).default('GZIP')
        attribute :error_output_prefix, Types::String.default('errors/')
        attribute :enable_data_transformation, Types::Bool.default(true)
        attribute :enable_data_validation, Types::Bool.default(true)
      end
    end
  end
end
