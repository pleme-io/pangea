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
      # Data source methods for AWS Local Zones

      # Query EC2 Local Gateway
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Local gateway attributes
      # @option attributes [String] :id The local gateway ID
      # @option attributes [String] :state The state of the local gateway
      # @option attributes [Hash<String,String>] :tags Tags to filter
      # @return [ResourceReference] Reference object with outputs
      def aws_ec2_local_gateway(name, attributes = {})
        optional_attrs = { id: nil, state: nil, tags: {} }
        gw_attrs = optional_attrs.merge(attributes)

        data(:aws_ec2_local_gateway, name) do
          id gw_attrs[:id] if gw_attrs[:id]
          state gw_attrs[:state] if gw_attrs[:state]
          tags gw_attrs[:tags] if gw_attrs[:tags].any?
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
          tags rt_attrs[:tags] if rt_attrs[:tags].any?
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
