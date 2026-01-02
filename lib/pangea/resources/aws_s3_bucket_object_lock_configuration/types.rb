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

require_relative 'types/validation'
require_relative 'types/instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS S3 Bucket Object Lock Configuration resources
        class S3BucketObjectLockConfigurationAttributes < Dry::Struct
          include InstanceMethods

          transform_keys(&:to_sym)

          # The name of the bucket for which object lock configuration is set
          attribute :bucket, Resources::Types::String

          # Expected bucket owner (optional for cross-account scenarios)
          attribute? :expected_bucket_owner, Resources::Types::String.optional

          # Object lock configuration status (Enabled is the only valid value)
          attribute :object_lock_enabled, Resources::Types::String.enum('Enabled').default('Enabled')

          # Token for making updates (prevents concurrent modification issues)
          attribute? :token, Resources::Types::String.optional

          # Default retention rule configuration
          attribute :rule, Resources::Types::Hash.schema(
            default_retention: Resources::Types::Hash.schema(
              # Retention mode: GOVERNANCE allows privileged users to modify/delete
              # COMPLIANCE prevents any modifications until retention period expires
              mode: Resources::Types::String.enum('GOVERNANCE', 'COMPLIANCE'),

              # Retention period - must specify either days OR years, not both
              days?: Resources::Types::Integer.constrained(gteq: 1, lteq: 36_500).optional,
              years?: Resources::Types::Integer.constrained(gteq: 1, lteq: 100).optional
            )
          ).default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            Validation.validate_bucket_name(attrs.bucket)

            if attrs.expected_bucket_owner
              Validation.validate_aws_account_id(attrs.expected_bucket_owner)
            end

            if attrs.rule[:default_retention]
              Validation.validate_default_retention(attrs.rule[:default_retention])
            end

            attrs
          end
        end
      end
    end
  end
end
