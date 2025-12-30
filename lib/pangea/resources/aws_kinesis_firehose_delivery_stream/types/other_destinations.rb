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
        # Other destination schemas for Kinesis Firehose Delivery Stream
        module FirehoseOtherDestinations
          include FirehoseSharedSchemas

          # Redshift destination configuration
          RedshiftConfiguration = Hash.schema(
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
          )

          # Splunk destination configuration
          SplunkConfiguration = Hash.schema(
            hec_endpoint: String,
            hec_token: String,
            hec_acknowledgment_timeout?: Integer.constrained(gteq: 180, lteq: 600).optional,
            hec_endpoint_type?: String.enum('Raw', 'Event').optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: String.enum('FailedEventsOnly', 'AllEvents').optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          )

          # HTTP endpoint destination configuration
          HttpEndpointConfiguration = Hash.schema(
            url: String,
            name?: String.optional,
            access_key?: String.optional,
            buffering_size?: FirehoseSharedSchemas::HttpBufferSize.optional,
            buffering_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: String.enum('FailedDataOnly', 'AllData').optional,
            request_configuration?: Hash.schema(
              content_encoding?: String.enum('NONE', 'GZIP').optional,
              common_attributes?: Hash.map(String, String).optional
            ).optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          )
        end
      end
    end
  end
end
