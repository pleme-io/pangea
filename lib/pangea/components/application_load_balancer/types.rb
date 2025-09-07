# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module ApplicationLoadBalancer
      # Health check configuration for target groups
      class HealthCheckConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :healthy_threshold, Types::Integer.default(3).constrained(gteq: 2, lteq: 10)
        attribute :unhealthy_threshold, Types::Integer.default(3).constrained(gteq: 2, lteq: 10) 
        attribute :timeout, Types::Integer.default(5).constrained(gteq: 2, lteq: 120)
        attribute :interval, Types::Integer.default(30).constrained(gteq: 5, lteq: 300)
        attribute :path, Types::String.default("/health")
        attribute :matcher, Types::String.default("200").constrained(format: /\A[\d,-]+\z/)
        attribute :protocol, Types::HealthCheckProtocol.default("HTTP")
        attribute :port, Types::String.default("traffic-port")
      end
      
      # Target group configuration
      class TargetGroupConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Types::String
        attribute :port, Types::Port.default(80)
        attribute :protocol, Types::String.default("HTTP").enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP')
        attribute :target_type, Types::AlbTargetType.default("instance")
        attribute :deregistration_delay, Types::Integer.default(300).constrained(gteq: 0, lteq: 3600)
        attribute :stickiness_enabled, Types::Bool.default(false)
        attribute :stickiness_duration, Types::Integer.optional.constrained(gteq: 1, lteq: 604800)
        attribute :health_check, HealthCheckConfig.default({})
      end
      
      # Listener configuration
      class ListenerConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :port, Types::ListenerPort.default(80)
        attribute :protocol, Types::ListenerProtocol.default("HTTP")
        attribute :ssl_policy, Types::SslPolicy.optional
        attribute :certificate_arn, Types::String.optional.constrained(format: /\Aarn:aws:acm:/)
        attribute :default_action_type, Types::String.default("forward").enum('forward', 'redirect', 'fixed-response')
        attribute :redirect_config, Types::Hash.optional
        attribute :fixed_response_config, Types::Hash.optional
      end
      
      # Main ALB component attributes
      class ApplicationLoadBalancerAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :vpc_ref, Types.Instance(Object)  # ResourceReference to VPC
        attribute :subnet_refs, Types::Array.of(Types.Instance(Object)).constrained(min_size: 2)  # ResourceReferences to subnets
        attribute :security_group_refs, Types::Array.of(Types.Instance(Object)).default([].freeze)  # ResourceReferences to security groups
        attribute :scheme, Types::String.default("internet-facing").enum('internet-facing', 'internal')
        attribute :ip_address_type, Types::String.default("ipv4").enum('ipv4', 'dualstack')
        attribute :idle_timeout, Types::Integer.default(60).constrained(gteq: 1, lteq: 4000)
        attribute :enable_deletion_protection, Types::Bool.default(false)
        attribute :enable_cross_zone_load_balancing, Types::Bool.default(false)
        attribute :enable_http2, Types::Bool.default(true)
        attribute :enable_waf_fail_open, Types::Bool.default(false)
        
        # Target groups to create
        attribute :target_groups, Types::Array.of(TargetGroupConfig).default([].freeze)
        
        # Listeners to create
        attribute :listeners, Types::Array.of(ListenerConfig).default([
          ListenerConfig.new(port: 80, protocol: "HTTP")
        ].freeze)
        
        # SSL/HTTPS configuration
        attribute :enable_https, Types::Bool.default(false)
        attribute :certificate_arn, Types::String.optional.constrained(format: /\Aarn:aws:acm:/)
        attribute :ssl_redirect, Types::Bool.default(true)  # Redirect HTTP to HTTPS
        
        # Access logging
        attribute :enable_access_logs, Types::Bool.default(true)
        attribute :access_logs_bucket, Types::String.optional
        attribute :access_logs_prefix, Types::String.default("alb-access-logs")
        
        # Common tags
        attribute :tags, Types::AwsTags.default({}.freeze)
        
        # Auto-create default target group
        attribute :create_default_target_group, Types::Bool.default(true)
        attribute :default_target_group_port, Types::Port.default(80)
        attribute :default_target_group_protocol, Types::String.default("HTTP")
        
        # Security enhancements
        attribute :enable_security_headers, Types::Bool.default(true)
        attribute :security_headers, Types::Hash.default({
          "X-Content-Type-Options" => "nosniff",
          "X-Frame-Options" => "DENY",
          "X-XSS-Protection" => "1; mode=block",
          "Strict-Transport-Security" => "max-age=31536000; includeSubDomains"
        }.freeze)
      end
    end
  end
end