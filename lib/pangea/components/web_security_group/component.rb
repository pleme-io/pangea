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

require 'pangea/components/base'
require 'pangea/components/web_security_group/types'
require 'pangea/resources/aws_security_group/resource'
require_relative 'rules'

module Pangea
  module Components
    module WebSecurityGroup
      include Base

      # Create a security group optimized for web servers with configurable access rules
      #
      # @param name [Symbol] The component name
      # @param attributes [Hash] WebSecurityGroup attributes
      # @return [ComponentReference] Reference object with security group resources and outputs
      def web_security_group(name, attributes = {})
        component_attrs = Types::WebSecurityGroupAttributes.new(attributes)
        vpc_id = extract_vpc_id(component_attrs.vpc_ref)

        ingress_rules = Rules.build_ingress_rules(component_attrs)
        egress_rules = Rules.build_egress_rules(component_attrs)

        # Create the security group
        sg_ref = aws_security_group(resource_name(name, :web_sg), {
          name: "#{name}-web-sg",
          description: component_attrs.description,
          vpc_id: vpc_id,
          ingress_rules: ingress_rules,
          egress_rules: egress_rules,
          tags: merge_component_tags(
            component_attrs.tags,
            {
              Name: "#{name}-web-sg",
              Type: "web",
              SecurityProfile: component_attrs.security_profile,
              Purpose: "Web server security group",
              RiskLevel: component_attrs.security_risk_level,
              HTTPEnabled: component_attrs.enable_http.to_s,
              HTTPSEnabled: component_attrs.enable_https.to_s,
              SSHEnabled: component_attrs.enable_ssh.to_s
            },
            :web_security_group,
            :security_group
          )
        })
        
        resources = {
          security_group: sg_ref
        }
        
        # Generate computed outputs
        outputs = {
          # Security group information
          security_group_id: sg_ref.id,
          security_group_arn: sg_ref.arn,
          security_group_name: sg_ref.name,
          
          # VPC information
          vpc_id: vpc_id,
          
          # Port configuration
          enabled_ports: component_attrs.enabled_ports,
          web_ports: component_attrs.web_ports,
          admin_ports: component_attrs.admin_ports,
          
          # Security analysis
          security_risk_level: component_attrs.security_risk_level,
          security_profile: component_attrs.security_profile,
          security_recommendations: component_attrs.security_recommendations,
          compliance_profile: component_attrs.compliance_profile,
          
          # Rule summaries
          inbound_rules_summary: component_attrs.inbound_rules_summary,
          outbound_rules_summary: component_attrs.outbound_rules_summary,
          ingress_rule_count: ingress_rules.length,
          egress_rule_count: egress_rules.length,
          
          # Access configuration
          http_enabled: component_attrs.enable_http,
          https_enabled: component_attrs.enable_https,
          ssh_enabled: component_attrs.enable_ssh,
          ping_enabled: component_attrs.enable_ping,
          outbound_internet_enabled: component_attrs.enable_outbound_internet,
          vpc_communication_enabled: component_attrs.enable_vpc_communication,
          
          # Network access
          allowed_cidr_blocks: component_attrs.allowed_cidr_blocks,
          ssh_cidr_blocks: component_attrs.ssh_cidr_blocks,
          internet_accessible: component_attrs.allowed_cidr_blocks.include?("0.0.0.0/0"),
          
          # Port analysis
          port_usage_analysis: component_attrs.port_usage_analysis
        }
        
        # Create and return component reference
        create_component_reference(
          type: :web_security_group,
          name: name,
          component_attributes: component_attrs,
          resources: resources,
          outputs: outputs
        )
      end

      private

      # Extract VPC ID from reference (handle both ResourceReference and String)
      # @param vpc_ref [String, ResourceReference] VPC reference
      # @return [String] VPC ID
      def extract_vpc_id(vpc_ref)
        case vpc_ref
        when String then vpc_ref
        else vpc_ref.id
        end
      end
    end
  end
end