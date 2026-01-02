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
require_relative 'types/helpers'
require_relative 'types/validation'
require_relative 'types/configs'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Systems Manager Parameter resources
        class SsmParameterAttributes < Dry::Struct
          include SsmParameterHelpers

          # Parameter name (required)
          attribute :name, Resources::Types::String

          # Parameter type
          attribute :type, Resources::Types::String.enum("String", "StringList", "SecureString")

          # Parameter value (required)
          attribute :value, Resources::Types::String

          # Parameter description
          attribute :description, Resources::Types::String.optional

          # KMS Key ID for SecureString parameters
          attribute :key_id, Resources::Types::String.optional

          # Parameter tier (Standard or Advanced)
          attribute :tier, Resources::Types::String.enum("Standard", "Advanced").default("Standard")

          # Allowed pattern for parameter value
          attribute :allowed_pattern, Resources::Types::String.optional

          # Data type for parameter
          attribute :data_type, Resources::Types::String.enum("text", "aws:ec2:image").optional

          # Overwrite existing parameter
          attribute :overwrite, Resources::Types::Bool.default(false)

          # Tags for the parameter
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            SsmParameterValidation.validate(attrs)
            attrs
          end
        end
      end
    end
  end
end
