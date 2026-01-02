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
      # Resource methods for AWS Local Zones

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
        optional_attrs = { tags: {} }
        assoc_attrs = optional_attrs.merge(attributes)

        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless assoc_attrs.key?(attr)
        end

        resource(:aws_ec2_local_gateway_route_table_vpc_association, name) do
          local_gateway_route_table_id assoc_attrs[:local_gateway_route_table_id]
          vpc_id assoc_attrs[:vpc_id]
          tags assoc_attrs[:tags] if assoc_attrs[:tags].any?
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
    end
  end
end
