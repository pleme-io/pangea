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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Managed Blockchain Node resources
        class ManagedBlockchainNodeAttributes < Dry::Struct
          extend ManagedBlockchainNodeValidation
          include ManagedBlockchainNodeInstanceMethods
          include ManagedBlockchainNodeCostAndSpecs

          transform_keys(&:to_sym)

          # Network ID (required)
          attribute :network_id, Resources::Types::String

          # Member ID (required for Hyperledger Fabric)
          attribute? :member_id, Resources::Types::String.optional

          # Node configuration (required)
          attribute :node_configuration, Resources::Types::Hash.schema(
            availability_zone: Resources::Types::String,
            instance_type: Resources::Types::String.enum(
              'bc.t3.small',
              'bc.t3.medium',
              'bc.t3.large',
              'bc.t3.xlarge',
              'bc.m5.large',
              'bc.m5.xlarge',
              'bc.m5.2xlarge',
              'bc.m5.4xlarge',
              'bc.c5.large',
              'bc.c5.xlarge',
              'bc.c5.2xlarge',
              'bc.c5.4xlarge'
            ),
            log_publishing_configuration?: Resources::Types::Hash.schema(
              fabric?: Resources::Types::Hash.schema(
                chaincode_logs?: Resources::Types::Hash.schema(
                  cloudwatch?: Resources::Types::Hash.schema(
                    enabled?: Resources::Types::Bool.optional
                  ).optional
                ).optional,
                peer_logs?: Resources::Types::Hash.schema(
                  cloudwatch?: Resources::Types::Hash.schema(
                    enabled?: Resources::Types::Bool.optional
                  ).optional
                ).optional
              ).optional
            ).optional,
            state_db?: Resources::Types::String.enum('LevelDB', 'CouchDB').optional
          )

          # Tags (optional)
          attribute? :tags, Resources::Types::AwsTags

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            validate_network_id(attrs.network_id)
            validate_member_id(attrs.member_id)
            validate_availability_zone(attrs.node_configuration[:availability_zone])
            validate_instance_type_for_workload(attrs)

            attrs
          end
        end
      end
    end
  end
end
