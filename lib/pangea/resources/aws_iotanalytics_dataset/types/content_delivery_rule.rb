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
    module AwsIotanalyticsDatasetTypes
      # Content delivery rules for dataset output
      class ContentDeliveryRule < Dry::Struct
        schema schema.strict

        # Entry name for the rule
        attribute :entry_name, Resources::Types::String

        # S3 destination configuration
        class Destination < Dry::Struct
          schema schema.strict

          class S3DestinationConfiguration < Dry::Struct
            schema schema.strict

            # S3 bucket name
            attribute :bucket, Resources::Types::String

            # Object key prefix
            attribute :key, Resources::Types::String

            # Glue database configuration
            class GlueConfiguration < Dry::Struct
              schema schema.strict

              # Glue table name
              attribute :table_name, Resources::Types::String

              # Glue database name
              attribute :database_name, Resources::Types::String
            end

            attribute? :glue_configuration, GlueConfiguration.optional

            # IAM role ARN for S3 access
            attribute :role_arn, Resources::Types::String
          end

          attribute? :s3_destination_configuration, S3DestinationConfiguration.optional
        end

        attribute :destination, Destination
      end
    end
  end
end
