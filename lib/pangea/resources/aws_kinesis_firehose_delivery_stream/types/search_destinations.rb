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
        # Search destination schemas for Kinesis Firehose Delivery Stream
        module FirehoseSearchDestinations
          include FirehoseSharedSchemas

          # Elasticsearch destination configuration
          ElasticsearchConfiguration = Hash.schema(
            role_arn: String,
            domain_arn: String,
            index_name: String,
            type_name?: String.optional,
            index_rotation_period?: FirehoseSharedSchemas::IndexRotationPeriod.optional,
            buffering_size?: FirehoseSharedSchemas::SearchBufferSize.optional,
            buffering_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          )

          # OpenSearch destination configuration
          AmazonOpensearchConfiguration = Hash.schema(
            role_arn: String,
            domain_arn: String,
            index_name: String,
            type_name?: String.optional,
            index_rotation_period?: FirehoseSharedSchemas::IndexRotationPeriod.optional,
            buffering_size?: FirehoseSharedSchemas::SearchBufferSize.optional,
            buffering_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: String.enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: Hash.optional,
            cloudwatch_logging_options?: Hash.optional
          )
        end
      end
    end
  end
end
