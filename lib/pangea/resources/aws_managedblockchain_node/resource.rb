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
require 'pangea/resources/aws_managedblockchain_node/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Managed Blockchain Node with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Managed blockchain node attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_managedblockchain_node(name, attributes = {})
        # Validate attributes using dry-struct
        node_attrs = Types::ManagedBlockchainNodeAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_managedblockchain_node, name) do
          # Set network ID
          network_id node_attrs.network_id
          
          # Set member ID if provided (required for Fabric)
          member_id node_attrs.member_id if node_attrs.member_id
          
          # Set node configuration
          node_configuration do
            # Set availability zone
            availability_zone node_attrs.node_configuration[:availability_zone]
            
            # Set instance type
            instance_type node_attrs.node_configuration[:instance_type]
            
            # Set state DB if provided (Fabric only)
            state_db node_attrs.node_configuration[:state_db] if node_attrs.node_configuration[:state_db]
            
            # Set log publishing configuration if provided
            if node_attrs.node_configuration[:log_publishing_configuration]
              log_publishing_configuration do
                if node_attrs.node_configuration[:log_publishing_configuration][:fabric]
                  fabric do
                    # Chaincode logs
                    if node_attrs.node_configuration[:log_publishing_configuration][:fabric][:chaincode_logs]
                      chaincode_logs do
                        if node_attrs.node_configuration[:log_publishing_configuration][:fabric][:chaincode_logs][:cloudwatch]
                          cloudwatch do
                            enabled node_attrs.node_configuration[:log_publishing_configuration][:fabric][:chaincode_logs][:cloudwatch][:enabled]
                          end
                        end
                      end
                    end
                    
                    # Peer logs
                    if node_attrs.node_configuration[:log_publishing_configuration][:fabric][:peer_logs]
                      peer_logs do
                        if node_attrs.node_configuration[:log_publishing_configuration][:fabric][:peer_logs][:cloudwatch]
                          cloudwatch do
                            enabled node_attrs.node_configuration[:log_publishing_configuration][:fabric][:peer_logs][:cloudwatch][:enabled]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
          
          # Set tags if provided
          if node_attrs.tags && !node_attrs.tags.empty?
            tags node_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_managedblockchain_node',
          name: name,
          resource_attributes: node_attrs.to_h,
          outputs: {
            id: "${aws_managedblockchain_node.#{name}.id}",
            arn: "${aws_managedblockchain_node.#{name}.arn}",
            network_id: "${aws_managedblockchain_node.#{name}.network_id}",
            member_id: "${aws_managedblockchain_node.#{name}.member_id}",
            status: "${aws_managedblockchain_node.#{name}.status}",
            availability_zone: "${aws_managedblockchain_node.#{name}.node_configuration.0.availability_zone}",
            instance_type: "${aws_managedblockchain_node.#{name}.node_configuration.0.instance_type}",
            state_db: "${aws_managedblockchain_node.#{name}.node_configuration.0.state_db}"
          },
          computed: {
            instance_family: node_attrs.instance_family,
            instance_size: node_attrs.instance_size,
            is_burstable: node_attrs.is_burstable?,
            is_compute_optimized: node_attrs.is_compute_optimized?,
            is_general_purpose: node_attrs.is_general_purpose?,
            uses_couchdb: node_attrs.uses_couchdb?,
            uses_leveldb: node_attrs.uses_leveldb?,
            chaincode_logging_enabled: node_attrs.chaincode_logging_enabled?,
            peer_logging_enabled: node_attrs.peer_logging_enabled?,
            any_logging_enabled: node_attrs.any_logging_enabled?,
            estimated_monthly_cost: node_attrs.estimated_monthly_cost,
            recommended_specs: node_attrs.recommended_specs,
            performance_tier: node_attrs.performance_tier,
            max_chaincode_connections: node_attrs.max_chaincode_connections
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)