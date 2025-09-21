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
      # Type-safe attributes for AWS Network ACL Rule resources
      class NetworkAclRuleAttributes < Dry::Struct
        # The ID of the network ACL (required)
        attribute :network_acl_id, Resources::Types::String
        
        # The rule number for ordering (required, 1-32766)
        attribute :rule_number, Resources::Types::Integer.constrained(gteq: 1, lteq: 32766)
        
        # Protocol (required) - can be protocol number or name
        # Common values: "tcp", "udp", "icmp", "-1" (all)
        attribute :protocol, Resources::Types::String
        
        # Rule action (required) - "allow" or "deny"
        attribute :rule_action, Resources::Types::String.enum("allow", "deny")
        
        # Direction of traffic (optional, default false = ingress)
        attribute :egress, Resources::Types::Bool.default(false)
        
        # IPv4 CIDR block (optional)
        attribute :cidr_block, Resources::Types::CidrBlock.optional
        
        # IPv6 CIDR block (optional)
        attributeipv6_cidr_block :, Resources::Types::String.optional.constrained(
          format: /\A(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\/\d{1,3}\z/
        )
        
        # Starting port for TCP/UDP (optional)
        attribute :from_port, Resources::Types::Port.optional
        
        # Ending port for TCP/UDP (optional)
        attribute :to_port, Resources::Types::Port.optional
        
        # ICMP type (optional, -1 for all)
        attribute :icmp_type, Resources::Types::Integer.optional.constrained(gteq: -1, lteq: 255)
        
        # ICMP code (optional, -1 for all)
        attribute :icmp_code, Resources::Types::Integer.optional.constrained(gteq: -1, lteq: 255)
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Must specify either cidr_block or ipv6_cidr_block
          if !attrs.cidr_block && !attrs.ipv6_cidr_block
            raise Dry::Struct::Error, "Must specify either 'cidr_block' or 'ipv6_cidr_block'"
          end
          
          # Cannot specify both cidr_block and ipv6_cidr_block
          if attrs.cidr_block && attrs.ipv6_cidr_block
            raise Dry::Struct::Error, "Cannot specify both 'cidr_block' and 'ipv6_cidr_block'"
          end
          
          # Port validations for TCP/UDP protocols
          if attrs.protocol && %w[tcp udp 6 17].include?(attrs.protocol.to_s.downcase)
            if !attrs.from_port || !attrs.to_port
              raise Dry::Struct::Error, "'from_port' and 'to_port' are required for TCP/UDP protocols"
            end
          end
          
          # ICMP validations
          if attrs.protocol && %w[icmp 1].include?(attrs.protocol.to_s.downcase)
            if attrs.from_port || attrs.to_port
              raise Dry::Struct::Error, "Cannot specify 'from_port' or 'to_port' for ICMP protocol, use 'icmp_type' and 'icmp_code' instead"
            end
          end
          
          # ICMPv6 validations
          if attrs.protocol && %w[icmpv6 58].include?(attrs.protocol.to_s.downcase)
            if !attrs.ipv6_cidr_block
              raise Dry::Struct::Error, "ICMPv6 protocol requires 'ipv6_cidr_block'"
            end
            if attrs.from_port || attrs.to_port
              raise Dry::Struct::Error, "Cannot specify 'from_port' or 'to_port' for ICMPv6 protocol, use 'icmp_type' and 'icmp_code' instead"
            end
          end
          
          # Protocol -1 (all) validations
          if attrs.protocol == "-1"
            if attrs.from_port || attrs.to_port || attrs.icmp_type || attrs.icmp_code
              raise Dry::Struct::Error, "Cannot specify ports or ICMP types when protocol is '-1' (all)"
            end
          end
          
          attrs
        end

        # Check if this is an ingress rule
        def ingress?
          !egress
        end
        
        # Check if this is an allow rule
        def allow?
          rule_action == "allow"
        end
        
        # Check if this is a deny rule
        def deny?
          rule_action == "deny"
        end
        
        # Check if this is an IPv6 rule
        def ipv6?
          !ipv6_cidr_block.nil?
        end
        
        # Check if this is an IPv4 rule
        def ipv4?
          !cidr_block.nil?
        end
        
        # Get the protocol name
        def protocol_name
          case protocol.to_s
          when "6" then "tcp"
          when "17" then "udp"
          when "1" then "icmp"
          when "58" then "icmpv6"
          when "-1" then "all"
          else protocol
          end
        end
        
        # Get the rule type description
        def rule_type
          "#{rule_action} #{egress ? 'egress' : 'ingress'}"
        end
      end
    end
      end
    end
  end
end