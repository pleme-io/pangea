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
        # Other destination schemas for Kinesis Firehose Delivery Stream
        module FirehoseOtherDestinations
          T = Dry.Types()

          # Redshift destination configuration
          RedshiftConfiguration = T['hash'].schema(
            role_arn: T['string'],
            cluster_jdbcurl: T['string'],
            username: T['string'],
            password: T['string'],
            data_table_name: T['string'],
            copy_options?: T['string'].optional,
            data_table_columns?: T['string'].optional,
            s3_backup_mode?: T['string'].enum('Disabled', 'Enabled').optional,
            s3_backup_configuration?: T['hash'].optional,
            processing_configuration?: T['hash'].optional,
            cloudwatch_logging_options?: T['hash'].optional
          )

          # Splunk destination configuration
          SplunkConfiguration = T['hash'].schema(
            hec_endpoint: T['string'],
            hec_token: T['string'],
            hec_acknowledgment_timeout?: T['integer'].constrained(gteq: 180, lteq: 600).optional,
            hec_endpoint_type?: T['string'].enum('Raw', 'Event').optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: T['string'].enum('FailedEventsOnly', 'AllEvents').optional,
            processing_configuration?: T['hash'].optional,
            cloudwatch_logging_options?: T['hash'].optional
          )

          # HTTP endpoint destination configuration
          HttpEndpointConfiguration = T['hash'].schema(
            url: T['string'],
            name?: T['string'].optional,
            access_key?: T['string'].optional,
            buffering_size?: FirehoseSharedSchemas::HttpBufferSize.optional,
            buffering_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: T['string'].enum('FailedDataOnly', 'AllData').optional,
            request_configuration?: T['hash'].schema(
              content_encoding?: T['string'].enum('NONE', 'GZIP').optional,
              common_attributes?: T['hash'].map(T['string'], T['string']).optional
            ).optional,
            processing_configuration?: T['hash'].optional,
            cloudwatch_logging_options?: T['hash'].optional
          )
        end
      end
    end
  end
end
