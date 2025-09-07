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
      # Type-safe attributes for AWS S3 Bucket Versioning resources
      class S3BucketVersioningAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Bucket name (required)
        attribute :bucket, Resources::Types::String

        # Versioning configuration (required)
        attribute :versioning_configuration, Resources::Types::Hash.schema(
          status: Resources::Types::String.enum('Enabled', 'Suspended'),
          mfa_delete?: Resources::Types::String.enum('Enabled', 'Disabled').optional
        )

        # Expected bucket owner for multi-account scenarios
        attribute? :expected_bucket_owner, Resources::Types::String.optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Ensure versioning_configuration is provided
          unless attrs.versioning_configuration
            raise Dry::Struct::Error, "versioning_configuration is required"
          end

          attrs
        end

        # Helper methods
        def versioning_enabled?
          versioning_configuration[:status] == 'Enabled'
        end

        def versioning_suspended?
          versioning_configuration[:status] == 'Suspended'
        end

        def mfa_delete_enabled?
          versioning_configuration[:mfa_delete] == 'Enabled'
        end

        def mfa_delete_configured?
          versioning_configuration.key?(:mfa_delete)
        end

        def status
          versioning_configuration[:status]
        end
      end
    end
      end
    end
  end
end