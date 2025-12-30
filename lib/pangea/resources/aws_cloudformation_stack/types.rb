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

require 'pangea/resources/types'

require_relative 'types/validation'
require_relative 'types/instance_methods'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CloudFormation Stack resources
        class CloudFormationStackAttributes < Dry::Struct
          include InstanceMethods

          # Stack name (required)
          attribute :name, Resources::Types::String

          # Template body or URL
          attribute :template_body, Resources::Types::String.optional
          attribute :template_url, Resources::Types::String.optional

          # Stack parameters
          attribute :parameters, Resources::Types::Hash.map(Types::String, Types::String).default({}.freeze)

          # Stack capabilities (for IAM resources)
          attribute :capabilities, Resources::Types::Array.of(
            Types::String.enum(
              "CAPABILITY_IAM",
              "CAPABILITY_NAMED_IAM",
              "CAPABILITY_AUTO_EXPAND"
            )
          ).default([].freeze)

          # Stack notification topics
          attribute :notification_arns, Resources::Types::Array.of(Types::String).default([].freeze)

          # Stack policy (JSON document)
          attribute :policy_body, Resources::Types::String.optional
          attribute :policy_url, Resources::Types::String.optional

          # Stack timeout (in minutes)
          attribute :timeout_in_minutes, Resources::Types::Integer.optional.constrained(gteq: 1)

          # Disable rollback on failure
          attribute :disable_rollback, Resources::Types::Bool.default(false)

          # Enable termination protection
          attribute :enable_termination_protection, Resources::Types::Bool.default(false)

          # IAM role for CloudFormation service
          attribute :iam_role_arn, Resources::Types::String.optional

          # Stack creation options
          attribute :on_failure, Resources::Types::String.enum("DO_NOTHING", "ROLLBACK", "DELETE").default("ROLLBACK")

          # Stack tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            Validation.validate_all(attrs)
            attrs
          end
        end
      end
    end
  end
end
