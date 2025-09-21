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
      # Type definitions for Network ACL rules
      class NetworkAclRule < Dry::Struct
        attribute :rule_number, Resources::Types::Integer
        attribute :protocol, Resources::Types::String  # "-1" for all
        attribute :action, Resources::Types::String.enum("allow", "deny")
        attribute :cidr_block, Resources::Types::String.optional
        attributeipv6_cidr_block :, Resources::Types::String.optional
        attribute :from_port, Resources::Types::Integer.optional
        attribute :to_port, Resources::Types::Integer.optional
        attribute :icmp_type, Resources::Types::Integer.optional
        attribute :icmp_code, Resources::Types::Integer.optional
        
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate rule number range
          if attrs.rule_number < 1 || attrs.rule_number > 32766
            raise Dry::Struct::Error, "Rule number must be between 1 and 32766"
          end
          
          # Must have either cidr_block or ipv6_cidr_block
          if !attrs.cidr_block && !attrs.ipv6_cidr_block
            raise Dry::Struct::Error, "Either 'cidr_block' or 'ipv6_cidr_block' must be specified"
          end
          
          # Port validation for TCP/UDP
          if attrs.protocol =~ /^(6|17|tcp|udp)$/i
            if !attrs.from_port || !attrs.to_port
              raise Dry::Struct::Error, "TCP/UDP rules require 'from_port' and 'to_port'"
            end
          end
          
          # ICMP validation
          if attrs.protocol =~ /^(1|icmp)$/i
            if attrs.from_port || attrs.to_port
              raise Dry::Struct::Error, "ICMP rules use 'icmp_type' and 'icmp_code', not ports"
            end
          end
          
          attrs
        end
      end
      
      # Type-safe attributes for AwsNetworkAcl resources
      # Provides an network ACL resource. You might set up network ACLs with rules similar to your security groups in order to add an additional layer of security to your VPC.
      class NetworkAclAttributes < Dry::Struct
        attribute :vpc_id, Resources::Types::String
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :ingress, Resources::Types::Array.of(NetworkAclRule).default([].freeze)
        attribute :egress, Resources::Types::Array.of(NetworkAclRule).default([].freeze)
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          # Convert rule hashes to NetworkAclRule objects
          if attributes[:ingress]
            attributes[:ingress] = attributes[:ingress].map { |rule| NetworkAclRule.new(rule) }
          end
          
          if attributes[:egress]
            attributes[:egress] = attributes[:egress].map { |rule| NetworkAclRule.new(rule) }
          end
          
          attrs = super(attributes)
          
          # Check for duplicate rule numbers
          ingress_numbers = attrs.ingress.map(&:rule_number)
          if ingress_numbers.uniq.size != ingress_numbers.size
            raise Dry::Struct::Error, "Duplicate ingress rule numbers found"
          end
          
          egress_numbers = attrs.egress.map(&:rule_number)
          if egress_numbers.uniq.size != egress_numbers.size
            raise Dry::Struct::Error, "Duplicate egress rule numbers found"
          end
          
          attrs
        end
        
        # Count ingress rules
        def ingress_rule_count
          ingress.size
        end
        
        # Count egress rules
        def egress_rule_count
          egress.size
        end
        
        # Check if default deny-all
        def is_restrictive?
          ingress.empty? && egress.empty?
        end
        
        # Find rule by number
        def find_ingress_rule(rule_number)
          ingress.find { |r| r.rule_number == rule_number }
        end
        
        def find_egress_rule(rule_number)
          egress.find { |r| r.rule_number == rule_number }
        end
        
        # Check if allows all traffic
        def allows_all_traffic?
          has_allow_all_rule?(ingress) && has_allow_all_rule?(egress)
        end
        
        private
        
        def has_allow_all_rule?(rules)
          rules.any? do |rule|
            rule.action == "allow" &&
            rule.protocol == "-1" &&
            (rule.cidr_block == "0.0.0.0/0" || rule.ipv6_cidr_block == "::/0")
          end
        end
      end
    end
      end
    end
  end
end