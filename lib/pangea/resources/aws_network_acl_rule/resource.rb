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
require 'pangea/resources/aws_network_acl_rule/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Network ACL Rule with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_network_acl_rule(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::NetworkAclRuleAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_network_acl_rule, name) do
          # Required attributes
          network_acl_id attrs.network_acl_id
          rule_number attrs.rule_number
          protocol attrs.protocol
          rule_action attrs.rule_action
          
          # Direction (egress is always specified, defaults to false)
          egress attrs.egress
          
          # CIDR blocks (one must be specified)
          cidr_block attrs.cidr_block if attrs.cidr_block
          ipv6_cidr_block attrs.ipv6_cidr_block if attrs.ipv6_cidr_block
          
          # Port range for TCP/UDP
          from_port attrs.from_port if attrs.from_port
          to_port attrs.to_port if attrs.to_port
          
          # ICMP type and code
          icmp_type attrs.icmp_type if attrs.icmp_type
          icmp_code attrs.icmp_code if attrs.icmp_code
          
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
          type: 'aws_network_acl_rule',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_network_acl_rule.#{name}.id}"
          },
          computed_properties: {
            ingress: attrs.ingress?,
            allow: attrs.allow?,
            deny: attrs.deny?,
            ipv6: attrs.ipv6?,
            ipv4: attrs.ipv4?,
            protocol_name: attrs.protocol_name,
            rule_type: attrs.rule_type
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)