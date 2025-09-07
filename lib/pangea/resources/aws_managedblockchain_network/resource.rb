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
require 'pangea/resources/aws_managedblockchain_network/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Managed Blockchain Network with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Managed blockchain network attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_managedblockchain_network(name, attributes = {})
        # Validate attributes using dry-struct
        network_attrs = Types::ManagedBlockchainNetworkAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_managedblockchain_network, name) do
          # Set network name
          name network_attrs.name
          
          # Set description if provided
          description network_attrs.description if network_attrs.description
          
          # Set framework and version
          framework network_attrs.framework
          framework_version network_attrs.framework_version
          
          # Set framework configuration
          if network_attrs.framework_configuration
            framework_configuration do
              # Hyperledger Fabric configuration
              if network_attrs.framework_configuration[:network_fabric_configuration]
                network_fabric_configuration do
                  edition network_attrs.framework_configuration[:network_fabric_configuration][:edition]
                end
              end
              
              # Ethereum configuration
              if network_attrs.framework_configuration[:network_ethereum_configuration]
                network_ethereum_configuration do
                  chain_id network_attrs.framework_configuration[:network_ethereum_configuration][:chain_id]
                end
              end
            end
          end
          
          # Set voting policy for Hyperledger Fabric
          if network_attrs.voting_policy
            voting_policy do
              if network_attrs.voting_policy[:approval_threshold_policy]
                approval_threshold_policy do
                  threshold_percentage network_attrs.voting_policy[:approval_threshold_policy][:threshold_percentage] if network_attrs.voting_policy[:approval_threshold_policy][:threshold_percentage]
                  proposal_duration_in_hours network_attrs.voting_policy[:approval_threshold_policy][:proposal_duration_in_hours] if network_attrs.voting_policy[:approval_threshold_policy][:proposal_duration_in_hours]
                  threshold_comparator network_attrs.voting_policy[:approval_threshold_policy][:threshold_comparator] if network_attrs.voting_policy[:approval_threshold_policy][:threshold_comparator]
                end
              end
            end
          end
          
          # Set member configuration
          member_configuration do
            name network_attrs.member_configuration[:name]
            description network_attrs.member_configuration[:description] if network_attrs.member_configuration[:description]
            
            # Framework-specific member configuration
            framework_configuration do
              if network_attrs.member_configuration[:framework_configuration][:member_fabric_configuration]
                member_fabric_configuration do
                  admin_username network_attrs.member_configuration[:framework_configuration][:member_fabric_configuration][:admin_username]
                  admin_password network_attrs.member_configuration[:framework_configuration][:member_fabric_configuration][:admin_password]
                end
              end
            end
            
            # Log publishing configuration
            if network_attrs.member_configuration[:log_publishing_configuration]
              log_publishing_configuration do
                if network_attrs.member_configuration[:log_publishing_configuration][:fabric]
                  fabric do
                    if network_attrs.member_configuration[:log_publishing_configuration][:fabric][:ca_logs]
                      ca_logs do
                        if network_attrs.member_configuration[:log_publishing_configuration][:fabric][:ca_logs][:cloudwatch]
                          cloudwatch do
                            enabled network_attrs.member_configuration[:log_publishing_configuration][:fabric][:ca_logs][:cloudwatch][:enabled]
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            
            # Member tags
            if network_attrs.member_configuration[:tags] && !network_attrs.member_configuration[:tags].empty?
              tags network_attrs.member_configuration[:tags]
            end
          end
          
          # Set network tags
          if network_attrs.tags && !network_attrs.tags.empty?
            tags network_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_managedblockchain_network',
          name: name,
          resource_attributes: network_attrs.to_h,
          outputs: {
            id: "${aws_managedblockchain_network.#{name}.id}",
            arn: "${aws_managedblockchain_network.#{name}.arn}",
            name: "${aws_managedblockchain_network.#{name}.name}",
            framework: "${aws_managedblockchain_network.#{name}.framework}",
            framework_version: "${aws_managedblockchain_network.#{name}.framework_version}",
            vpc_endpoint_service_name: "${aws_managedblockchain_network.#{name}.vpc_endpoint_service_name}",
            member_id: "${aws_managedblockchain_network.#{name}.member.0.id}",
            member_name: "${aws_managedblockchain_network.#{name}.member.0.name}"
          },
          computed: {
            is_hyperledger_fabric: network_attrs.is_hyperledger_fabric?,
            is_ethereum: network_attrs.is_ethereum?,
            edition: network_attrs.edition,
            is_starter_edition: network_attrs.is_starter_edition?,
            is_standard_edition: network_attrs.is_standard_edition?,
            chain_id: network_attrs.chain_id,
            approval_threshold: network_attrs.approval_threshold,
            proposal_duration_hours: network_attrs.proposal_duration_hours,
            cloudwatch_logging_enabled: network_attrs.cloudwatch_logging_enabled?,
            estimated_monthly_cost: network_attrs.estimated_monthly_cost,
            consensus_mechanism: network_attrs.consensus_mechanism,
            network_type: network_attrs.network_type
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)