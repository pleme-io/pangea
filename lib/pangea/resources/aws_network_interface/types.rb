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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsNetworkInterface resources
      # Provides a network interface resource for EC2 instances with multiple IPs and security groups
      class NetworkInterfaceAttributes < Dry::Struct
        # Required subnet for the ENI
        attribute :subnet_id, Resources::Types::String
        
        # Optional attributes
        attribute :description, Resources::Types::String.optional
        attribute :private_ips, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :private_ips_count, Resources::Types::Integer.optional
        attribute :security_groups, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :source_dest_check, Resources::Types::Bool.optional.default(true)
        attribute :interface_type, Resources::Types::String.enum("efa", "branch", "trunk").optional
        attributeipv4_prefix_count :, Resources::Types::Integer.optional
        attributeipv4_prefixes :, Resources::Types::Array.of(Types::String).default([].freeze)
        attributeipv6_address_count :, Resources::Types::Integer.optional
        attributeipv6_addresses :, Resources::Types::Array.of(Types::String).default([].freeze)
        attributeipv6_prefix_count :, Resources::Types::Integer.optional
        attributeipv6_prefixes :, Resources::Types::Array.of(Types::String).default([].freeze)
        
        # Attachment configuration (for attaching at creation)
        attribute :attachment, Resources::Types::Hash.default({}.freeze)
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Cannot specify both private_ips and private_ips_count
          if attrs.private_ips.any? && attrs.private_ips_count
            raise Dry::Struct::Error, "Cannot specify both 'private_ips' and 'private_ips_count'"
          end
          
          # Cannot specify both ipv6_addresses and ipv6_address_count
          if attrs.ipv6_addresses.any? && attrs.ipv6_address_count
            raise Dry::Struct::Error, "Cannot specify both 'ipv6_addresses' and 'ipv6_address_count'"
          end
          
          # Validate attachment structure if present
          if attrs.attachment.any?
            required_keys = [:instance, :device_index]
            missing_keys = required_keys - attrs.attachment.keys
            unless missing_keys.empty?
              raise Dry::Struct::Error, "Attachment requires: #{missing_keys.join(', ')}"
            end
          end
          
          attrs
        end

        # Check if ENI is attached at creation
        def attached_at_creation?
          attachment.any?
        end
        
        # Check if using specific private IPs
        def explicit_private_ips?
          private_ips.any?
        end
        
        # Check if using IPv6
        def ipv6_enabled?
          ipv6_addresses.any? || ipv6_address_count || ipv6_prefixes.any? || ipv6_prefix_count
        end
        
        # Get interface type name
        def interface_type_name
          case interface_type
          when "efa"
            "Elastic Fabric Adapter"
          when "branch"
            "Branch Network Interface"
          when "trunk"
            "Trunk Network Interface"
          else
            "Standard Network Interface"
          end
        end
      end
    end
      end
    end
  end
end