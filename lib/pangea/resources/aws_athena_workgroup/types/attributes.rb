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
        # Type-safe attributes for AWS Athena Workgroup resources
        class AthenaWorkgroupAttributes < Dry::Struct
          extend AthenaWorkgroupClassMethods
          extend AthenaWorkgroupValidation
          include AthenaWorkgroupInstanceMethods

          # Workgroup name (required)
          attribute :name, Resources::Types::String

          # Workgroup description
          attribute :description, Resources::Types::String.optional

          # State of the workgroup
          attribute :state, Resources::Types::String.enum('ENABLED', 'DISABLED').default('ENABLED')

          # Force destroy workgroup and contents
          attribute :force_destroy, Resources::Types::Bool.default(false)

          # Workgroup configuration
          attribute :configuration, Resources::Types::Hash.schema(
            # Query result configuration
            result_configuration?: Types::Hash.schema(
              output_location?: Types::String.optional,
              encryption_configuration?: Types::Hash.schema(
                encryption_option: Types::String.enum('SSE_S3', 'SSE_KMS', 'CSE_KMS'),
                kms_key_id?: Types::String.optional
              ).optional,
              expected_bucket_owner?: Types::String.optional,
              acl_configuration?: Types::Hash.schema(
                s3_acl_option: Types::String.enum('BUCKET_OWNER_FULL_CONTROL')
              ).optional
            ).optional,

            # Execution configuration
            enforce_workgroup_configuration?: Types::Bool.optional,
            publish_cloudwatch_metrics_enabled?: Types::Bool.optional,
            bytes_scanned_cutoff_per_query?: Types::Integer.optional,
            requester_pays_enabled?: Types::Bool.optional,

            # Engine version
            engine_version?: Types::Hash.schema(
              selected_engine_version?: Types::String.optional,
              effective_engine_version?: Types::String.optional
            ).optional,

            # Result configuration override
            result_configuration_updates?: Types::Hash.schema(
              output_location?: Types::String.optional,
              remove_output_location?: Types::Bool.optional,
              encryption_configuration?: Types::Hash.schema(
                encryption_option: Types::String.enum('SSE_S3', 'SSE_KMS', 'CSE_KMS'),
                kms_key_id?: Types::String.optional
              ).optional,
              remove_encryption_configuration?: Types::Bool.optional
            ).optional,

            # Execution role
            execution_role?: Types::String.optional,

            # Customer content encryption
            customer_content_encryption_configuration?: Types::Hash.schema(
              kms_key_id: Types::String
            ).optional
          ).optional

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_workgroup_name(attrs.name)
            validate_kms_encryption(attrs.configuration)
            validate_bytes_cutoff(attrs.configuration)
            attrs
          end
        end
      end
    end
  end
end
