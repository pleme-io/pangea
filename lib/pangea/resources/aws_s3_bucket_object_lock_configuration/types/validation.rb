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

module Pangea
  module Resources
    module AWS
      module Types
        class S3BucketObjectLockConfigurationAttributes
          # Validation methods for S3 bucket object lock configuration
          module Validation
            def self.validate_bucket_name(bucket_name)
              if bucket_name.length < 3 || bucket_name.length > 63
                raise Dry::Struct::Error, 'Bucket name must be between 3 and 63 characters'
              end

              unless bucket_name.match?(/^[a-z0-9][a-z0-9\-]*[a-z0-9]$/)
                raise Dry::Struct::Error, 'Invalid bucket name format'
              end

              true
            end

            def self.validate_aws_account_id(account_id)
              unless account_id.match?(/^\d{12}$/)
                raise Dry::Struct::Error, 'Expected bucket owner must be a 12-digit AWS account ID'
              end

              true
            end

            def self.validate_default_retention(retention_config)
              days = retention_config[:days]
              years = retention_config[:years]

              if days && years
                raise Dry::Struct::Error, 'Cannot specify both days and years in default retention'
              end

              if !days && !years
                raise Dry::Struct::Error, 'Must specify either days or years in default retention'
              end

              if days && (days < 1 || days > 36_500)
                raise Dry::Struct::Error, 'Retention days must be between 1 and 36500 (approximately 100 years)'
              end

              if years && (years < 1 || years > 100)
                raise Dry::Struct::Error, 'Retention years must be between 1 and 100'
              end

              if days && days > 36_500
                raise Dry::Struct::Error, "Retention period of #{days} days exceeds maximum recommended period"
              end

              true
            end
          end
        end
      end
    end
  end
end
