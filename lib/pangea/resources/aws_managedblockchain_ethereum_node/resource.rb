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
require 'pangea/resources/aws_managedblockchain_ethereum_node/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Managed Blockchain Ethereum Node
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Ethereum node attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_managedblockchain_ethereum_node(name, attributes = {})
        # Validate attributes using dry-struct
        node_attrs = Types::ManagedBlockchainEthereumNodeAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_managedblockchain_ethereum_node, name) do
          # Set network ID
          network_id node_attrs.network_id
          
          # Set node configuration
          node_configuration do
            instance_type node_attrs.node_configuration[:instance_type]
            
            if node_attrs.node_configuration[:availability_zone]
              availability_zone node_attrs.node_configuration[:availability_zone]
            end
            
            if node_attrs.node_configuration[:subnet_id]
              subnet_id node_attrs.node_configuration[:subnet_id]
            end
          end
          
          # Set client request token if provided
          if node_attrs.client_request_token
            client_request_token node_attrs.client_request_token
          end
          
          # Set tags
          if node_attrs.tags && !node_attrs.tags.empty?
            tags node_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_managedblockchain_ethereum_node',
          name: name,
          resource_attributes: node_attrs.to_h,
          outputs: {
            arn: "${aws_managedblockchain_ethereum_node.#{name}.arn}",
            id: "${aws_managedblockchain_ethereum_node.#{name}.id}",
            node_id: "${aws_managedblockchain_ethereum_node.#{name}.node_id}",
            network_id: "${aws_managedblockchain_ethereum_node.#{name}.network_id}",
            status: "${aws_managedblockchain_ethereum_node.#{name}.status}",
            creation_date: "${aws_managedblockchain_ethereum_node.#{name}.creation_date}",
            endpoint: "${aws_managedblockchain_ethereum_node.#{name}.endpoint}",
            instance_type: "${aws_managedblockchain_ethereum_node.#{name}.instance_type}"
          },
          computed: {
            is_mainnet_node: node_attrs.is_mainnet_node?,
            is_testnet_node: node_attrs.is_testnet_node?,
            instance_family: node_attrs.instance_family,
            instance_size: node_attrs.instance_size,
            estimated_monthly_cost: node_attrs.estimated_monthly_cost,
            storage_capacity_gb: node_attrs.storage_capacity_gb,
            network_throughput_mbps: node_attrs.network_throughput_mbps,
            supports_archival_data: node_attrs.supports_archival_data?,
            is_high_availability: node_attrs.is_high_availability?,
            blockchain_protocol: node_attrs.blockchain_protocol
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)