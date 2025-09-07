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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_managedblockchain_accessor/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Managed Blockchain Accessor for blockchain network access
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Managed blockchain accessor attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_managedblockchain_accessor(name, attributes = {})
        # Validate attributes using dry-struct
        accessor_attrs = Types::ManagedBlockchainAccessorAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_managedblockchain_accessor, name) do
          # Set accessor type
          accessor_type accessor_attrs.accessor_type
          
          # Set network type if provided
          if accessor_attrs.network_type
            network_type accessor_attrs.network_type
          end
          
          # Set billing token for Ethereum accessors
          if accessor_attrs.billing_token
            billing_token accessor_attrs.billing_token
          end
          
          # Set tags
          if accessor_attrs.tags && !accessor_attrs.tags.empty?
            tags accessor_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_managedblockchain_accessor',
          name: name,
          resource_attributes: accessor_attrs.to_h,
          outputs: {
            arn: "${aws_managedblockchain_accessor.#{name}.arn}",
            id: "${aws_managedblockchain_accessor.#{name}.id}",
            accessor_type: "${aws_managedblockchain_accessor.#{name}.accessor_type}",
            network_type: "${aws_managedblockchain_accessor.#{name}.network_type}",
            status: "${aws_managedblockchain_accessor.#{name}.status}",
            creation_date: "${aws_managedblockchain_accessor.#{name}.creation_date}",
            billing_token: "${aws_managedblockchain_accessor.#{name}.billing_token}"
          },
          computed: {
            is_ethereum_accessor: accessor_attrs.is_ethereum_accessor?,
            is_hyperledger_accessor: accessor_attrs.is_hyperledger_accessor?,
            supports_mainnet: accessor_attrs.supports_mainnet?,
            supports_testnet: accessor_attrs.supports_testnet?,
            has_billing_token: accessor_attrs.has_billing_token?,
            estimated_monthly_cost: accessor_attrs.estimated_monthly_cost,
            access_type: accessor_attrs.access_type,
            blockchain_framework: accessor_attrs.blockchain_framework
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)