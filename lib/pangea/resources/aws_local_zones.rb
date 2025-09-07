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
      # AWS Local Zones - Run latency-sensitive applications closer to end users
      # Local Zones provide single-digit millisecond latency to end users by bringing AWS compute, storage, database, and other services closer to large population centers
      
      # Query EC2 Local Gateway
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Local gateway attributes
      # @option attributes [String] :id The local gateway ID
      # @option attributes [String] :state The state of the local gateway
      # @option attributes [Hash<String,String>] :tags Tags to filter
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_local_gateway(name, attributes = {})
        optional_attrs = {
          id: nil,
          state: nil,
          tags: {}
        }
        
        gw_attrs = optional_attrs.merge(attributes)
        
        data(:aws_ec2_local_gateway, name) do
          id gw_attrs[:id] if gw_attrs[:id]
          state gw_attrs[:state] if gw_attrs[:state]
          
          if gw_attrs[:tags].any?
            tags gw_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_ec2_local_gateway',
          name: name,
          resource_attributes: gw_attrs,
          outputs: {
            id: "${data.aws_ec2_local_gateway.#{name}.id}",
            outpost_arn: "${data.aws_ec2_local_gateway.#{name}.outpost_arn}",
            owner_id: "${data.aws_ec2_local_gateway.#{name}.owner_id}",
            state: "${data.aws_ec2_local_gateway.#{name}.state}",
            tags: "${data.aws_ec2_local_gateway.#{name}.tags}"
          }
        )
      end
      
      # Query EC2 Local Gateway Route Table
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route table attributes
      # @option attributes [String] :local_gateway_route_table_id The route table ID
      # @option attributes [String] :local_gateway_id The local gateway ID
      # @option attributes [String] :outpost_arn The outpost ARN
      # @option attributes [String] :state The state
      # @option attributes [Hash<String,String>] :tags Tags to filter
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_local_gateway_route_table(name, attributes = {})
        optional_attrs = {
          local_gateway_route_table_id: nil,
          local_gateway_id: nil,
          outpost_arn: nil,
          state: nil,
          tags: {}
        }
        
        rt_attrs = optional_attrs.merge(attributes)
        
        data(:aws_ec2_local_gateway_route_table, name) do
          local_gateway_route_table_id rt_attrs[:local_gateway_route_table_id] if rt_attrs[:local_gateway_route_table_id]
          local_gateway_id rt_attrs[:local_gateway_id] if rt_attrs[:local_gateway_id]
          outpost_arn rt_attrs[:outpost_arn] if rt_attrs[:outpost_arn]
          state rt_attrs[:state] if rt_attrs[:state]
          
          if rt_attrs[:tags].any?
            tags rt_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_ec2_local_gateway_route_table',
          name: name,
          resource_attributes: rt_attrs,
          outputs: {
            id: "${data.aws_ec2_local_gateway_route_table.#{name}.id}",
            local_gateway_id: "${data.aws_ec2_local_gateway_route_table.#{name}.local_gateway_id}",
            local_gateway_route_table_id: "${data.aws_ec2_local_gateway_route_table.#{name}.local_gateway_route_table_id}",
            outpost_arn: "${data.aws_ec2_local_gateway_route_table.#{name}.outpost_arn}",
            owner_id: "${data.aws_ec2_local_gateway_route_table.#{name}.owner_id}",
            state: "${data.aws_ec2_local_gateway_route_table.#{name}.state}",
            tags: "${data.aws_ec2_local_gateway_route_table.#{name}.tags}"
          }
        )
      end
      
      # Create a Local Gateway Route
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Route attributes
      # @option attributes [String] :destination_cidr_block (required) The destination CIDR block
      # @option attributes [String] :local_gateway_route_table_id (required) The local gateway route table ID
      # @option attributes [String] :local_gateway_virtual_interface_group_id (required) The virtual interface group ID
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_local_gateway_route(name, attributes = {})
        required_attrs = %i[destination_cidr_block local_gateway_route_table_id local_gateway_virtual_interface_group_id]
        
        route_attrs = attributes
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless route_attrs.key?(attr)
        end
        
        resource(:aws_ec2_local_gateway_route, name) do
          destination_cidr_block route_attrs[:destination_cidr_block]
          local_gateway_route_table_id route_attrs[:local_gateway_route_table_id]
          local_gateway_virtual_interface_group_id route_attrs[:local_gateway_virtual_interface_group_id]
        end
        
        ResourceReference.new(
          type: 'aws_ec2_local_gateway_route',
          name: name,
          resource_attributes: route_attrs,
          outputs: {
            id: "${aws_ec2_local_gateway_route.#{name}.id}"
          }
        )
      end
      
      # Associate a Local Gateway Route Table with a VPC
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Association attributes
      # @option attributes [String] :local_gateway_route_table_id (required) The local gateway route table ID
      # @option attributes [String] :vpc_id (required) The VPC ID
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_local_gateway_route_table_vpc_association(name, attributes = {})
        required_attrs = %i[local_gateway_route_table_id vpc_id]
        optional_attrs = {
          tags: {}
        }
        
        assoc_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless assoc_attrs.key?(attr)
        end
        
        resource(:aws_ec2_local_gateway_route_table_vpc_association, name) do
          local_gateway_route_table_id assoc_attrs[:local_gateway_route_table_id]
          vpc_id assoc_attrs[:vpc_id]
          
          if assoc_attrs[:tags].any?
            tags assoc_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_ec2_local_gateway_route_table_vpc_association',
          name: name,
          resource_attributes: assoc_attrs,
          outputs: {
            id: "${aws_ec2_local_gateway_route_table_vpc_association.#{name}.id}",
            local_gateway_id: "${aws_ec2_local_gateway_route_table_vpc_association.#{name}.local_gateway_id}",
            local_gateway_route_table_id: "${aws_ec2_local_gateway_route_table_vpc_association.#{name}.local_gateway_route_table_id}",
            vpc_id: "${aws_ec2_local_gateway_route_table_vpc_association.#{name}.vpc_id}"
          }
        )
      end
      
      # Query Local Gateway Virtual Interface Group Association
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Association attributes
      # @option attributes [String] :id The association ID
      # @option attributes [String] :local_gateway_id The local gateway ID
      # @option attributes [String] :local_gateway_virtual_interface_id The virtual interface ID
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_local_gateway_virtual_interface_group_association(name, attributes = {})
        optional_attrs = {
          id: nil,
          local_gateway_id: nil,
          local_gateway_virtual_interface_id: nil
        }
        
        assoc_attrs = optional_attrs.merge(attributes)
        
        data(:aws_ec2_local_gateway_virtual_interface_group, name) do
          id assoc_attrs[:id] if assoc_attrs[:id]
          local_gateway_id assoc_attrs[:local_gateway_id] if assoc_attrs[:local_gateway_id]
          local_gateway_virtual_interface_ids [assoc_attrs[:local_gateway_virtual_interface_id]] if assoc_attrs[:local_gateway_virtual_interface_id]
        end
        
        ResourceReference.new(
          type: 'aws_ec2_local_gateway_virtual_interface_group',
          name: name,
          resource_attributes: assoc_attrs,
          outputs: {
            id: "${data.aws_ec2_local_gateway_virtual_interface_group.#{name}.id}",
            local_gateway_id: "${data.aws_ec2_local_gateway_virtual_interface_group.#{name}.local_gateway_id}",
            local_gateway_virtual_interface_ids: "${data.aws_ec2_local_gateway_virtual_interface_group.#{name}.local_gateway_virtual_interface_ids}",
            tags: "${data.aws_ec2_local_gateway_virtual_interface_group.#{name}.tags}"
          }
        )
      end
    end
  end
end