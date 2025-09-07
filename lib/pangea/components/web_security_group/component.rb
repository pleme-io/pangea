# frozen_string_literal: true

require 'pangea/components/base'
require 'pangea/components/web_security_group/types'
require 'pangea/resources/aws_security_group/resource'

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
        # Validate attributes using dry-struct
        component_attrs = Types::WebSecurityGroupAttributes.new(attributes)
        
        # Extract VPC ID from reference (handle both ResourceReference and String)
        vpc_id = case component_attrs.vpc_ref
                 when String then component_attrs.vpc_ref
                 else component_attrs.vpc_ref.id
                 end
        
        # Build ingress rules based on configuration
        ingress_rules = []
        
        # HTTP access
        if component_attrs.enable_http
          ingress_rules << {
            from_port: component_attrs.http_port,
            to_port: component_attrs.http_port,
            protocol: "tcp",
            cidr_blocks: component_attrs.allowed_cidr_blocks,
            description: "HTTP web traffic"
          }
        end
        
        # HTTPS access
        if component_attrs.enable_https
          ingress_rules << {
            from_port: component_attrs.https_port,
            to_port: component_attrs.https_port,
            protocol: "tcp",
            cidr_blocks: component_attrs.allowed_cidr_blocks,
            description: "HTTPS web traffic"
          }
        end
        
        # SSH access (with separate CIDR blocks for better security)
        if component_attrs.enable_ssh
          ingress_rules << {
            from_port: component_attrs.ssh_port,
            to_port: component_attrs.ssh_port,
            protocol: "tcp",
            cidr_blocks: component_attrs.ssh_cidr_blocks,
            description: "SSH administrative access"
          }
        end
        
        # Custom ports
        component_attrs.custom_ports.each do |port|
          ingress_rules << {
            from_port: port,
            to_port: port,
            protocol: "tcp",
            cidr_blocks: component_attrs.allowed_cidr_blocks,
            description: "Custom port #{port}"
          }
        end
        
        # ICMP ping (if enabled)
        if component_attrs.enable_ping
          ingress_rules << {
            from_port: -1,
            to_port: -1,
            protocol: "icmp",
            cidr_blocks: component_attrs.allowed_cidr_blocks,
            description: "ICMP ping"
          }
        end
        
        # Build egress rules based on configuration
        egress_rules = []
        
        # Outbound internet access
        if component_attrs.enable_outbound_internet
          egress_rules << {
            from_port: 0,
            to_port: 65535,
            protocol: "tcp",
            cidr_blocks: ["0.0.0.0/0"],
            description: "All outbound TCP traffic to internet"
          }
          
          egress_rules << {
            from_port: 0,
            to_port: 65535,
            protocol: "udp",
            cidr_blocks: ["0.0.0.0/0"],
            description: "All outbound UDP traffic to internet"
          }
        end
        
        # VPC communication (if enabled and different from internet access)
        if component_attrs.enable_vpc_communication && !component_attrs.enable_outbound_internet
          # This would need VPC CIDR - for now we'll use a placeholder
          # In practice, this should get the VPC CIDR from the vpc_ref
          egress_rules << {
            from_port: 0,
            to_port: 65535,
            protocol: "tcp",
            cidr_blocks: ["10.0.0.0/8"], # Placeholder - should be actual VPC CIDR
            description: "All TCP traffic within VPC"
          }
        end
        
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
    end
  end
end