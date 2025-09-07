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
require 'pangea/resources/aws_workspaces_ip_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS WorkSpaces IP Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] WorkSpaces IP Group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_workspaces_ip_group(name, attributes = {})
        # Validate attributes using dry-struct
        ip_group_attrs = Types::Types::WorkspacesIpGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_workspaces_ip_group, name) do
          group_name ip_group_attrs.group_name
          group_desc ip_group_attrs.group_desc
          
          # User rules
          if ip_group_attrs.user_rules.any?
            ip_group_attrs.user_rules.each do |rule|
              user_rules do
                ip_rule rule.ip_rule
                rule_desc rule.rule_desc if rule.rule_desc && !rule.rule_desc.empty?
              end
            end
          end
          
          # Apply tags if present
          if ip_group_attrs.tags.any?
            tags do
              ip_group_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_workspaces_ip_group',
          name: name,
          resource_attributes: ip_group_attrs.to_h,
          outputs: {
            id: "${aws_workspaces_ip_group.#{name}.id}",
            group_name: ip_group_attrs.group_name,
            group_desc: ip_group_attrs.group_desc
          },
          computed_properties: {
            total_rules: ip_group_attrs.total_rules,
            has_public_ips: ip_group_attrs.has_public_ips?,
            has_private_ips: ip_group_attrs.has_private_ips?,
            ip_ranges: ip_group_attrs.ip_ranges,
            rule_details: ip_group_attrs.user_rules.map { |rule|
              {
                ip_rule: rule.ip_rule,
                rule_desc: rule.rule_desc,
                is_single_host: rule.is_single_host?,
                is_broad_range: rule.is_broad_range?,
                estimated_hosts: rule.estimated_hosts,
                network_address: rule.network_address,
                cidr_prefix: rule.cidr_prefix
              }
            }
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)