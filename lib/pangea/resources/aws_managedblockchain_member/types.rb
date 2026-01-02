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
        # Type-safe attributes for AWS Managed Blockchain Member resources
        class ManagedBlockchainMemberAttributes < Dry::Struct
          extend ManagedBlockchainMemberValidation
          include ManagedBlockchainMemberInstanceMethods

          transform_keys(&:to_sym)

          # Network ID (required)
          attribute :network_id, Resources::Types::String

          # Member configuration (required)
          attribute :member_configuration, Resources::Types::Hash.schema(
            name: Resources::Types::String,
            description?: Resources::Types::String.optional,
            framework_configuration: Resources::Types::Hash.schema(
              member_fabric_configuration?: Resources::Types::Hash.schema(
                admin_username: Resources::Types::String,
                admin_password: Resources::Types::String
              ).optional
            ),
            log_publishing_configuration?: Resources::Types::Hash.schema(
              fabric?: Resources::Types::Hash.schema(
                ca_logs?: Resources::Types::Hash.schema(
                  cloudwatch?: Resources::Types::Hash.schema(
                    enabled?: Resources::Types::Bool.optional
                  ).optional
                ).optional
              ).optional
            ).optional,
            tags?: Resources::Types::Hash.schema(
              Resources::Types::String => Resources::Types::String
            ).optional
          )

          # Invitation ID (required for joining existing networks)
          attribute? :invitation_id, Resources::Types::String.optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_network_id(attrs.network_id)
            validate_invitation_id(attrs.invitation_id)
            validate_member_name(attrs.member_configuration[:name])

            fabric_config = attrs.member_configuration[:framework_configuration][:member_fabric_configuration]
            validate_fabric_configuration(fabric_config) if fabric_config

            attrs
          end
        end
      end
    end
  end
end
