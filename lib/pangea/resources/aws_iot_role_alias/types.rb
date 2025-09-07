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
    # AWS IoT Role Alias Types
    # 
    # Role aliases allow IoT devices to assume IAM roles without embedding credentials.
    # This enables secure access to AWS services from IoT devices using X.509 certificate
    # authentication and temporary credentials via AWS STS.
    module AwsIotRoleAliasTypes
      # Main attributes for IoT role alias resource
      class Attributes < Dry::Struct
        schema schema.strict

        # Name of the role alias (unique identifier)
        attribute :alias, Resources::Types::String

        # ARN of the IAM role to be assumed
        attribute :role_arn, Resources::Types::String

        # Optional duration in seconds for credentials (3600-43200)
        attribute :credential_duration_seconds, Resources::Types::Integer.constrained(gteq: 3600, lteq: 43200).optional

        # Resource tags for organization and billing
        attribute :tags, Resources::Types::Hash.map(Types::String, Types::String).optional
      end

      # Output attributes from role alias resource
      class Outputs < Dry::Struct
        schema schema.strict

        # The role alias ARN
        attribute :arn, Resources::Types::String

        # The role alias name/identifier
        attribute :alias, Resources::Types::String

        # The ARN of the associated IAM role
        attribute :role_arn, Resources::Types::String

        # The credential duration in seconds
        attribute :credential_duration_seconds, Resources::Types::Integer

        # The unique role alias ID
        attribute :id, Resources::Types::String
      end
    end
  end
end