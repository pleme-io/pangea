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
        # Search destination schemas for Kinesis Firehose Delivery Stream
        module FirehoseSearchDestinations
          T = Dry.Types()

          # Elasticsearch destination configuration
          ElasticsearchConfiguration = T['hash'].schema(
            role_arn: T['string'],
            domain_arn: T['string'],
            index_name: T['string'],
            type_name?: T['string'].optional,
            index_rotation_period?: FirehoseSharedSchemas::IndexRotationPeriod.optional,
            buffering_size?: FirehoseSharedSchemas::SearchBufferSize.optional,
            buffering_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: T['string'].enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: T['hash'].optional,
            cloudwatch_logging_options?: T['hash'].optional
          )

          # OpenSearch destination configuration
          AmazonOpensearchConfiguration = T['hash'].schema(
            role_arn: T['string'],
            domain_arn: T['string'],
            index_name: T['string'],
            type_name?: T['string'].optional,
            index_rotation_period?: FirehoseSharedSchemas::IndexRotationPeriod.optional,
            buffering_size?: FirehoseSharedSchemas::SearchBufferSize.optional,
            buffering_interval?: FirehoseSharedSchemas::BufferInterval.optional,
            retry_duration?: FirehoseSharedSchemas::RetryDuration.optional,
            s3_backup_mode?: T['string'].enum('FailedDocumentsOnly', 'AllDocuments').optional,
            processing_configuration?: T['hash'].optional,
            cloudwatch_logging_options?: T['hash'].optional
          )
        end
      end
    end
  end
end
