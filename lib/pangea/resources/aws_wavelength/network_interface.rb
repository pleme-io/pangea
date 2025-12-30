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
      # Create a Wavelength network interface
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Network interface attributes
      # @option attributes [String] :subnet_id (required) The subnet ID (must be in Wavelength zone)
      # @option attributes [String] :description Interface description
      # @option attributes [Array<String>] :security_groups Security group IDs
      # @option attributes [String] :private_ip Private IP address
      # @option attributes [Boolean] :source_dest_check Source/destination check (default: true)
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_network_interface(name, attributes = {})
        required_attrs = %i[subnet_id]
        optional_attrs = {
          description: nil,
          security_groups: [],
          private_ip: nil,
          source_dest_check: true,
          tags: {}
        }

        eni_attrs = optional_attrs.merge(attributes)

        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless eni_attrs.key?(attr)
        end

        resource(:aws_network_interface, name) do
          subnet_id eni_attrs[:subnet_id]
          description eni_attrs[:description] if eni_attrs[:description]
          security_groups eni_attrs[:security_groups] if eni_attrs[:security_groups].any?
          private_ip eni_attrs[:private_ip] if eni_attrs[:private_ip]
          source_dest_check eni_attrs[:source_dest_check]

          if eni_attrs[:tags].any?
            tags eni_attrs[:tags]
          end
        end

        ResourceReference.new(
          type: 'aws_network_interface',
          name: name,
          resource_attributes: eni_attrs,
          outputs: {
            id: "${aws_network_interface.#{name}.id}",
            arn: "${aws_network_interface.#{name}.arn}",
            mac_address: "${aws_network_interface.#{name}.mac_address}",
            private_dns_name: "${aws_network_interface.#{name}.private_dns_name}",
            private_ip: "${aws_network_interface.#{name}.private_ip}",
            private_ips: "${aws_network_interface.#{name}.private_ips}",
            security_groups: "${aws_network_interface.#{name}.security_groups}",
            subnet_id: "${aws_network_interface.#{name}.subnet_id}"
          }
        )
      end
    end
  end
end
