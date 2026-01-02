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
        class BlockchainQueryAttributes < Dry::Struct
          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_query_name!(attrs)
            validate_query_string!(attrs)
            validate_s3_bucket!(attrs)
            validate_kms_key!(attrs)
            validate_schedule!(attrs)

            attrs
          end

          class << self
            private

            def validate_query_name!(attrs)
              return if attrs.query_name.match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)

              raise Dry::Struct::Error,
                    'query_name must be 1-128 characters long and contain only ' \
                    'alphanumeric characters, hyphens, and underscores'
            end

            def validate_query_string!(attrs)
              sql = attrs.query_string.strip.downcase

              unless sql.start_with?('select')
                raise Dry::Struct::Error, 'query_string must be a SELECT statement'
              end

              dangerous_keywords = %w[drop delete update insert alter create truncate]
              return unless dangerous_keywords.any? { |keyword| sql.include?(keyword) }

              raise Dry::Struct::Error, 'query_string contains potentially dangerous SQL keywords'
            end

            def validate_s3_bucket!(attrs)
              bucket_name = attrs.output_configuration[:s3_configuration][:bucket_name]
              return if bucket_name.match?(/\A[a-z0-9\-\.]{3,63}\z/)

              raise Dry::Struct::Error, 'bucket_name must be a valid S3 bucket name'
            end

            def validate_kms_key!(attrs)
              encryption_config = attrs.output_configuration[:s3_configuration][:encryption_configuration]
              return unless encryption_config && encryption_config[:encryption_option] == 'SSE_KMS'

              unless encryption_config[:kms_key]
                raise Dry::Struct::Error, 'kms_key is required when encryption_option is SSE_KMS'
              end

              kms_pattern = /\A(arn:aws:kms:[a-z0-9\-]+:\d{12}:key\/[a-f0-9\-]+|alias\/[a-zA-Z0-9\-_\/]+)\z/
              return if encryption_config[:kms_key].match?(kms_pattern)

              raise Dry::Struct::Error, 'kms_key must be a valid KMS key ARN or alias'
            end

            def validate_schedule!(attrs)
              return unless attrs.schedule_configuration

              schedule_expr = attrs.schedule_configuration[:schedule_expression]
              schedule_pattern = /\A(rate\([0-9]+ (minute|minutes|hour|hours|day|days)\)|cron\(.+\))\z/
              return if schedule_expr.match?(schedule_pattern)

              raise Dry::Struct::Error,
                    'schedule_expression must be a valid AWS EventBridge schedule expression'
            end
          end
        end
      end
    end
  end
end
