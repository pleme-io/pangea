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
require_relative 'types/validators'
require_relative 'types/helpers'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CloudFormation Stack Set resources
        class CloudFormationStackSetAttributes < Dry::Struct
          include CloudFormationStackSetHelpers

          # Stack set name (required)
          attribute :name, Resources::Types::String

          # Template body or URL
          attribute :template_body, Resources::Types::String.optional
          attribute :template_url, Resources::Types::String.optional

          # Stack set description
          attribute :description, Resources::Types::String.optional

          # Stack set parameters
          attribute :parameters, Resources::Types::Hash.map(
            Types::String,
            Types::String
          ).default({}.freeze)

          # Stack set capabilities (for IAM resources)
          attribute :capabilities, Resources::Types::Array.of(
            Types::String.enum(
              'CAPABILITY_IAM',
              'CAPABILITY_NAMED_IAM',
              'CAPABILITY_AUTO_EXPAND'
            )
          ).default([].freeze)

          # Permission model
          attribute :permission_model, Resources::Types::String.enum(
            'SERVICE_MANAGED',
            'SELF_MANAGED'
          )

          # Auto deployment configuration (for SERVICE_MANAGED)
          attribute :auto_deployment, Resources::Types::Hash.schema(
            enabled?: Types::Bool.default(false),
            retain_stacks_on_account_removal?: Types::Bool.default(false)
          ).optional

          # Administration role ARN (for SELF_MANAGED)
          attribute :administration_role_arn, Resources::Types::String.optional

          # Execution role name (for SELF_MANAGED)
          attribute :execution_role_name, Resources::Types::String.optional

          # Operation preferences
          attribute :operation_preferences, Resources::Types::Hash.schema(
            region_concurrency_type?: Types::String.enum('SEQUENTIAL', 'PARALLEL').optional,
            max_concurrent_percentage?: Types::Integer.optional.constrained(gteq: 1, lteq: 100),
            max_concurrent_count?: Types::Integer.optional.constrained(gteq: 1),
            failure_tolerance_percentage?: Types::Integer.optional.constrained(gteq: 0, lteq: 100),
            failure_tolerance_count?: Types::Integer.optional.constrained(gteq: 0)
          ).optional

          # Call as operation (immediate deployment)
          attribute :call_as, Resources::Types::String.enum(
            'SELF',
            'DELEGATED_ADMIN'
          ).default('SELF')

          # Stack set tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation using extracted validators
          def self.new(attributes = {})
            attrs = super(attributes)
            CloudFormationStackSetValidators.validate!(attrs)
            attrs
          end
        end
      end
    end
  end
end
