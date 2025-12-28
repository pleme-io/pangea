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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # IoT Analytics Channel name validation
      IotAnalyticsChannelName = String.constrained(format: /\A[a-zA-Z0-9_]{1,128}\z/).constructor { |value|
        unless value.match?(/\A[a-zA-Z_]/) && !value.end_with?('_')
          raise Dry::Types::ConstraintError, "IoT Analytics Channel name must start with letter or underscore and cannot end with underscore"
        end
        value
      }

      # IoT Analytics Datastore name validation
      IotAnalyticsDatastoreName = String.constrained(format: /\A[a-zA-Z0-9_]{1,128}\z/).constructor { |value|
        unless value.match?(/\A[a-zA-Z_]/) && !value.end_with?('_')
          raise Dry::Types::ConstraintError, "IoT Analytics Datastore name must start with letter or underscore and cannot end with underscore"
        end
        value
      }

      IotAnalyticsRetentionPeriod = Integer.constrained(gteq: 1, lteq: 2147483647)
      IotAnalyticsFileFormatType = String.enum('JSON', 'PARQUET')
      IotAnalyticsDatasetContentType = String.enum('CSV', 'JSON')

      IotAnalyticsS3Configuration = Hash.schema(
        bucket: S3BucketName,
        key?: String.optional,
        role_arn: String.constrained(format: /\Aarn:aws:iam::\d{12}:role\//),
        file_format_configuration?: Hash.schema(
          json_configuration?: Hash.schema({}).optional,
          parquet_configuration?: Hash.schema({}).optional
        ).optional
      )

      IotAnalyticsLambdaConfiguration = Hash.schema(
        lambda_name: String.constrained(format: /\A[a-zA-Z0-9\-_]{1,64}\z/),
        batch_size?: Integer.constrained(gteq: 1, lteq: 1000).optional
      )
    end
  end
end
