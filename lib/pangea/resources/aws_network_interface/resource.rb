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
require 'pangea/resources/aws_network_interface/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create and manage AWS Network Interface (ENI) resources
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_network_interface(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::NetworkInterfaceAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_network_interface, name) do
          # Required attributes
          subnet_id attrs.subnet_id
          
          # Optional attributes
          description attrs.description if attrs.description
          private_ips attrs.private_ips if attrs.private_ips.any?
          private_ips_count attrs.private_ips_count if attrs.private_ips_count
          security_groups attrs.security_groups if attrs.security_groups.any?
          source_dest_check attrs.source_dest_check unless attrs.source_dest_check.nil?
          interface_type attrs.interface_type if attrs.interface_type
          
          # IPv4 prefix configuration
          ipv4_prefix_count attrs.ipv4_prefix_count if attrs.ipv4_prefix_count
          ipv4_prefixes attrs.ipv4_prefixes if attrs.ipv4_prefixes.any?
          
          # IPv6 configuration
          ipv6_address_count attrs.ipv6_address_count if attrs.ipv6_address_count
          ipv6_addresses attrs.ipv6_addresses if attrs.ipv6_addresses.any?
          ipv6_prefix_count attrs.ipv6_prefix_count if attrs.ipv6_prefix_count
          ipv6_prefixes attrs.ipv6_prefixes if attrs.ipv6_prefixes.any?
          
          # Attachment configuration
          if attrs.attachment.any?
            attachment do
              instance attrs.attachment[:instance]
              device_index attrs.attachment[:device_index]
            end
          end
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_network_interface',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            # Core identification
            id: "${aws_network_interface.#{name}.id}",
            arn: "${aws_network_interface.#{name}.arn}",
            
            # Network configuration
            mac_address: "${aws_network_interface.#{name}.mac_address}",
            private_dns_name: "${aws_network_interface.#{name}.private_dns_name}",
            private_ip: "${aws_network_interface.#{name}.private_ip}",
            private_ips: "${aws_network_interface.#{name}.private_ips}",
            
            # IPv6 configuration
            ipv6_addresses: "${aws_network_interface.#{name}.ipv6_addresses}",
            
            # Security and subnet
            security_groups: "${aws_network_interface.#{name}.security_groups}",
            subnet_id: "${aws_network_interface.#{name}.subnet_id}",
            
            # Ownership
            owner_id: "${aws_network_interface.#{name}.owner_id}",
            
            # Interface type
            interface_type: "${aws_network_interface.#{name}.interface_type}",
            
            # Attachment info (if attached)
            attachment: "${aws_network_interface.#{name}.attachment}"
          },
          computed_properties: {
            attached_at_creation: attrs.attached_at_creation?,
            explicit_private_ips: attrs.explicit_private_ips?,
            ipv6_enabled: attrs.ipv6_enabled?,
            interface_type_name: attrs.interface_type_name
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)