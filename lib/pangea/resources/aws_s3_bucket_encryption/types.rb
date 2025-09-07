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
    module AWS
      module Types
      # Type-safe attributes for AWS S3 Bucket Encryption resources
      class S3BucketEncryptionAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Bucket name (required)
        attribute :bucket, Resources::Types::String

        # Server-side encryption configuration (required)
        attribute :server_side_encryption_configuration, Resources::Types::Hash.schema(
          rule: Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              apply_server_side_encryption_by_default: Resources::Types::Hash.schema(
                sse_algorithm: Resources::Types::String.enum('AES256', 'aws:kms', 'aws:kms:dsse'),
                kms_master_key_id?: Resources::Types::String.optional
              ),
              bucket_key_enabled?: Resources::Types::Bool.optional
            )
          )
        )

        # Expected bucket owner for multi-account scenarios
        attribute? :expected_bucket_owner, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate encryption configuration exists
          unless attrs.server_side_encryption_configuration[:rule]&.any?
            raise Dry::Struct::Error, "server_side_encryption_configuration must have at least one rule"
          end

          # Validate KMS configurations
          attrs.server_side_encryption_configuration[:rule].each_with_index do |rule, index|
            encryption_config = rule[:apply_server_side_encryption_by_default]
            algorithm = encryption_config[:sse_algorithm]

            # Validate KMS key is provided when using KMS encryption
            if (algorithm == 'aws:kms' || algorithm == 'aws:kms:dsse') && 
               encryption_config[:kms_master_key_id].nil?
              raise Dry::Struct::Error, "kms_master_key_id is required when using '#{algorithm}' encryption in rule #{index}"
            end

            # Validate AES256 doesn't have KMS key
            if algorithm == 'AES256' && encryption_config[:kms_master_key_id]
              raise Dry::Struct::Error, "kms_master_key_id should not be specified when using 'AES256' encryption in rule #{index}"
            end
          end

          attrs
        end

        # Helper methods
        def encryption_rules_count
          server_side_encryption_configuration[:rule].size
        end

        def primary_encryption_algorithm
          server_side_encryption_configuration[:rule].first[:apply_server_side_encryption_by_default][:sse_algorithm]
        end

        def uses_kms_encryption?
          server_side_encryption_configuration[:rule].any? do |rule|
            alg = rule[:apply_server_side_encryption_by_default][:sse_algorithm]
            alg == 'aws:kms' || alg == 'aws:kms:dsse'
          end
        end

        def uses_aes256_encryption?
          server_side_encryption_configuration[:rule].any? do |rule|
            rule[:apply_server_side_encryption_by_default][:sse_algorithm] == 'AES256'
          end
        end

        def bucket_key_enabled?
          server_side_encryption_configuration[:rule].any? do |rule|
            rule[:bucket_key_enabled] == true
          end
        end

        def kms_key_ids
          server_side_encryption_configuration[:rule]
            .map { |rule| rule[:apply_server_side_encryption_by_default][:kms_master_key_id] }
            .compact
        end
      end
    end
      end
    end
  end
end