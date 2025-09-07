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
      # Type-safe attributes for AWS S3 Bucket Public Access Block resources
      class S3BucketPublicAccessBlockAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Bucket name (required)
        attribute :bucket, Resources::Types::String

        # Block public ACLs (optional, default false)
        attribute? :block_public_acls, Resources::Types::Bool.optional

        # Block public policy (optional, default false)
        attribute? :block_public_policy, Resources::Types::Bool.optional

        # Ignore public ACLs (optional, default false)
        attribute? :ignore_public_acls, Resources::Types::Bool.optional

        # Restrict public buckets (optional, default false)
        attribute? :restrict_public_buckets, Resources::Types::Bool.optional

        # Expected bucket owner for multi-account scenarios
        attribute? :expected_bucket_owner, Resources::Types::String.optional

        # Helper methods
        def fully_blocked?
          block_public_acls == true &&
            block_public_policy == true &&
            ignore_public_acls == true &&
            restrict_public_buckets == true
        end

        def partially_blocked?
          [block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets].any? { |setting| setting == true }
        end

        def allows_public_access?
          !partially_blocked?
        end

        def blocked_settings_count
          [block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets].count { |setting| setting == true }
        end

        def security_level
          case blocked_settings_count
          when 0
            'open'
          when 1..3
            'restricted'
          when 4
            'secure'
          else
            'unknown'
          end
        end

        def configuration_summary
          {
            block_public_acls: block_public_acls || false,
            block_public_policy: block_public_policy || false,
            ignore_public_acls: ignore_public_acls || false,
            restrict_public_buckets: restrict_public_buckets || false
          }
        end
      end
    end
      end
    end
  end
end