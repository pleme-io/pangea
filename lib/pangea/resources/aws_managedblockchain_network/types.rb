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
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Managed Blockchain Network resources
        class ManagedBlockchainNetworkAttributes < Dry::Struct
          include ManagedBlockchainNetworkHelpers

          transform_keys(&:to_sym)

          # Network name (required)
          attribute :name, Resources::Types::String

          # Description (optional)
          attribute? :description, Resources::Types::String.optional

          # Framework (required)
          attribute :framework, Resources::Types::String.enum(
            'HYPERLEDGER_FABRIC',
            'ETHEREUM'
          )

          # Framework version (required)
          attribute :framework_version, Resources::Types::String

          # Framework configuration (required for Hyperledger Fabric)
          attribute? :framework_configuration, Resources::Types::Hash.schema(
            network_fabric_configuration?: Resources::Types::Hash.schema(
              edition: Resources::Types::String.enum('STARTER', 'STANDARD')
            ).optional,
            network_ethereum_configuration?: Resources::Types::Hash.schema(
              chain_id: Resources::Types::String
            ).optional
          ).optional

          # Voting policy (required for Hyperledger Fabric)
          attribute? :voting_policy, Resources::Types::Hash.schema(
            approval_threshold_policy?: Resources::Types::Hash.schema(
              threshold_percentage?: Resources::Types::Integer.constrained(gteq: 0, lteq: 100).optional,
              proposal_duration_in_hours?: Resources::Types::Integer.constrained(gteq: 1, lteq: 168).optional,
              threshold_comparator?: Resources::Types::String.enum('GREATER_THAN', 'GREATER_THAN_OR_EQUAL_TO').optional
            ).optional
          ).optional

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
            tags?: Resources::Types::Hash.optional
          )

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            ManagedBlockchainNetworkValidation.validate_name(attrs.name)
            ManagedBlockchainNetworkValidation.validate_member_name(attrs.member_configuration[:name])

            case attrs.framework
            when 'HYPERLEDGER_FABRIC'
              ManagedBlockchainNetworkValidation.validate_fabric_configuration(attrs)
            when 'ETHEREUM'
              ManagedBlockchainNetworkValidation.validate_ethereum_configuration(attrs)
            end

            attrs
          end
        end
      end
    end
  end
end
