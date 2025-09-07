# frozen_string_literal: true

require 'dry-struct'
require 'pangea/components/types'

module Pangea
  module Components
    module WebSecurityGroup
      module Types
        # WebSecurityGroup component attributes with comprehensive validation
        class WebSecurityGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :vpc_ref, Components::Types::VpcReference
          attribute :description, Resources::Types::String.default("Web servers security group")
          attribute :enable_http, Components::Types::Bool.default(true)
          attribute :enable_https, Components::Types::Bool.default(true)
          attribute :enable_ssh, Components::Types::Bool.default(false)
          attribute :http_port, Resources::Types::Port.default(80)
          attribute :https_port, Resources::Types::Port.default(443)
          attribute :ssh_port, Resources::Types::Port.default(22)
          attribute :custom_ports, Resources::Types::Array.of(Resources::Types::Port).default([].freeze)
          attribute :allowed_cidr_blocks, Components::Types::SubnetCidrBlocks.default(["0.0.0.0/0"].freeze)
          attribute :ssh_cidr_blocks, Components::Types::SubnetCidrBlocks.default(["10.0.0.0/8"].freeze)
          attribute :enable_ping, Components::Types::Bool.default(false)
          attribute :enable_outbound_internet, Components::Types::Bool.default(true)
          attribute :enable_vpc_communication, Components::Types::Bool.default(true)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :security_profile, Resources::Types::String.enum('basic', 'standard', 'strict', 'custom').default('standard')
          
          # Custom validation for security group configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate at least one web protocol is enabled
            if !attrs[:enable_http] && !attrs[:enable_https] && (attrs[:custom_ports] || []).empty?
              raise Dry::Struct::Error, "Web security group must enable at least HTTP, HTTPS, or custom ports"
            end
            
            # Validate SSH configuration security
            if attrs[:enable_ssh] && attrs[:ssh_cidr_blocks]
              if attrs[:ssh_cidr_blocks].include?("0.0.0.0/0")
                puts "WARNING: SSH access from 0.0.0.0/0 is a security risk. Consider restricting to specific IP ranges."
              end
            end
            
            # Validate custom ports are not duplicates of standard ports
            custom_ports = attrs[:custom_ports] || []
            standard_ports = []
            standard_ports << attrs[:http_port] if attrs[:enable_http]
            standard_ports << attrs[:https_port] if attrs[:enable_https]
            standard_ports << attrs[:ssh_port] if attrs[:enable_ssh]
            
            duplicates = custom_ports & standard_ports
            unless duplicates.empty?
              raise Dry::Struct::Error, "Custom ports #{duplicates} conflict with enabled standard ports"
            end
            
            # Validate CIDR blocks format
            all_cidrs = (attrs[:allowed_cidr_blocks] || []) + (attrs[:ssh_cidr_blocks] || [])
            all_cidrs.each do |cidr|
              unless cidr.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
                raise Dry::Struct::Error, "Invalid CIDR block format: #{cidr}"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def enabled_ports
            ports = []
            ports << http_port if enable_http
            ports << https_port if enable_https
            ports << ssh_port if enable_ssh
            ports + custom_ports
          end
          
          def web_ports
            ports = []
            ports << http_port if enable_http
            ports << https_port if enable_https
            ports + custom_ports.select { |port| [80, 8080, 443, 8443].include?(port) }
          end
          
          def admin_ports
            ports = []
            ports << ssh_port if enable_ssh
            ports + custom_ports.select { |port| [22, 3389, 5985, 5986].include?(port) }
          end
          
          def security_risk_level
            risks = []
            risks << 'SSH_OPEN_INTERNET' if enable_ssh && ssh_cidr_blocks.include?("0.0.0.0/0")
            risks << 'HTTP_ONLY' if enable_http && !enable_https
            risks << 'WIDE_OPEN_ACCESS' if allowed_cidr_blocks.include?("0.0.0.0/0")
            risks << 'PING_ENABLED' if enable_ping
            
            case risks.length
            when 0 then 'low'
            when 1..2 then 'medium'
            when 3.. then 'high'
            end
          end
          
          def security_recommendations
            recommendations = []
            
            if enable_ssh && ssh_cidr_blocks.include?("0.0.0.0/0")
              recommendations << "Restrict SSH access to specific IP ranges or use a bastion host"
            end
            
            if enable_http && !enable_https
              recommendations << "Enable HTTPS and consider redirecting HTTP to HTTPS"
            end
            
            if allowed_cidr_blocks.include?("0.0.0.0/0") && security_profile == 'strict'
              recommendations << "Consider restricting web access to specific IP ranges or CloudFront"
            end
            
            if !enable_outbound_internet
              recommendations << "Ensure instances can reach required external services"
            end
            
            recommendations
          end
          
          def compliance_profile
            features = []
            features << 'HTTPS_ENABLED' if enable_https
            features << 'SSH_RESTRICTED' if enable_ssh && !ssh_cidr_blocks.include?("0.0.0.0/0")
            features << 'OUTBOUND_CONTROLLED' if !enable_outbound_internet
            features << 'VPC_ISOLATION' if enable_vpc_communication && !allowed_cidr_blocks.include?("0.0.0.0/0")
            features << 'NO_PING' if !enable_ping
            
            {
              level: case features.length
                     when 0..1 then 'basic'
                     when 2..3 then 'standard'  
                     when 4..5 then 'strict'
                     end,
              features: features
            }
          end
          
          def inbound_rules_summary
            rules = []
            
            if enable_http
              rules << {
                protocol: 'tcp',
                port: http_port,
                sources: allowed_cidr_blocks,
                description: 'HTTP web traffic'
              }
            end
            
            if enable_https
              rules << {
                protocol: 'tcp',
                port: https_port,
                sources: allowed_cidr_blocks,
                description: 'HTTPS web traffic'
              }
            end
            
            if enable_ssh
              rules << {
                protocol: 'tcp',
                port: ssh_port,
                sources: ssh_cidr_blocks,
                description: 'SSH administrative access'
              }
            end
            
            custom_ports.each do |port|
              rules << {
                protocol: 'tcp',
                port: port,
                sources: allowed_cidr_blocks,
                description: "Custom port #{port}"
              }
            end
            
            if enable_ping
              rules << {
                protocol: 'icmp',
                port: -1,
                sources: allowed_cidr_blocks,
                description: 'ICMP ping'
              }
            end
            
            rules
          end
          
          def outbound_rules_summary
            rules = []
            
            if enable_outbound_internet
              rules << {
                protocol: 'tcp',
                ports: '0-65535',
                destinations: ['0.0.0.0/0'],
                description: 'All outbound TCP traffic to internet'
              }
              
              rules << {
                protocol: 'udp', 
                ports: '0-65535',
                destinations: ['0.0.0.0/0'],
                description: 'All outbound UDP traffic to internet'
              }
            end
            
            if enable_vpc_communication
              rules << {
                protocol: 'tcp',
                ports: '0-65535', 
                destinations: ['vpc_cidr'],
                description: 'All TCP traffic within VPC'
              }
            end
            
            rules
          end
          
          def port_usage_analysis
            {
              web_ports: web_ports.length,
              admin_ports: admin_ports.length,
              custom_ports: custom_ports.length,
              total_ports: enabled_ports.length,
              has_ssl: enable_https,
              has_admin_access: enable_ssh || admin_ports.any?,
              internet_accessible: allowed_cidr_blocks.include?("0.0.0.0/0")
            }
          end
        end
      end
    end
  end
end