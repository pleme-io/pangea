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
require_relative 'types/filter'
require_relative 'types/destination'
require_relative 'types/rule'
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS S3 Bucket Replication Configuration resources
        class S3BucketReplicationConfigurationAttributes < Dry::Struct
          include S3BucketReplicationHelpers

          transform_keys(&:to_sym)

          # The name of the bucket for which replication configuration is set
          attribute :bucket, Resources::Types::String

          # IAM role ARN that S3 can assume to replicate objects
          attribute :role, Resources::Types::String

          # Array of replication rules
          attribute :rule, S3BucketReplicationRule::Rules

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            S3BucketReplicationValidators.validate_all(attrs)
            attrs
          end
        end
      end
    end
  end
end
