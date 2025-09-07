# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module GlobalTrafficManager
      # Endpoint configuration for traffic management
      class EndpointConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :region, Types::String
        attribute :endpoint_id, Types::String
        attribute :endpoint_type, Types::String.enum('ALB', 'NLB', 'INSTANCE', 'EIP', 'EC2').default('ALB')
        attribute :weight, Types::Integer.default(100)
        attribute :priority, Types::Integer.default(100)
        attribute :enabled, Types::Bool.default(true)
        attribute :health_check_enabled, Types::Bool.default(true)
        attribute :client_ip_preservation, Types::Bool.default(false)
        attribute :metadata, Types::Hash.default({}.freeze)
      end
      
      # Traffic policy configuration
      class TrafficPolicyConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :policy_name, Types::String
        attribute :policy_type, Types::String.enum('latency', 'weighted', 'geoproximity', 'geolocation', 'failover', 'multivalue').default('latency')
        attribute :health_check_interval, Types::Integer.default(30)
        attribute :health_check_path, Types::String.default('/health')
        attribute :health_check_protocol, Types::String.enum('HTTP', 'HTTPS', 'TCP').default('HTTP')
        attribute :unhealthy_threshold, Types::Integer.default(3)
        attribute :healthy_threshold, Types::Integer.default(2)
        attribute :health_check_timeout, Types::Integer.default(5)
      end
      
      # Geo-routing configuration
      class GeoRoutingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(false)
        attribute :default_location, Types::String.default('*')
        attribute :location_rules, Types::Array.of(Types::Hash).default([].freeze)
        attribute :bias_adjustments, Types::Hash.default({}.freeze)
        attribute :continent_mapping, Types::Hash.default({}.freeze)
      end
      
      # Performance optimization configuration
      class PerformanceConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :tcp_optimization, Types::Bool.default(true)
        attribute :flow_logs_enabled, Types::Bool.default(true)
        attribute :flow_logs_s3_bucket, Types::String.optional
        attribute :flow_logs_s3_prefix, Types::String.default('global-traffic-flow-logs/')
        attribute :connection_draining_timeout, Types::Integer.default(30)
        attribute :idle_timeout, Types::Integer.default(60)
      end
      
      # Advanced routing features
      class AdvancedRoutingConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :weighted_distribution, Types::Hash.default({}.freeze)
        attribute :canary_deployment, Types::Hash.default({}.freeze)
        attribute :blue_green_deployment, Types::Hash.default({}.freeze)
        attribute :traffic_dials, Types::Hash.default({}.freeze)
        attribute :custom_headers, Types::Array.of(Types::Hash).default([].freeze)
        attribute :request_routing_rules, Types::Array.of(Types::Hash).default([].freeze)
      end
      
      # Monitoring and observability configuration
      class ObservabilityConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :cloudwatch_enabled, Types::Bool.default(true)
        attribute :detailed_metrics, Types::Bool.default(true)
        attribute :access_logs_enabled, Types::Bool.default(true)
        attribute :distributed_tracing, Types::Bool.default(true)
        attribute :real_user_monitoring, Types::Bool.default(false)
        attribute :synthetic_checks, Types::Array.of(Types::Hash).default([].freeze)
        attribute :alerting_enabled, Types::Bool.default(true)
        attribute :notification_topic_ref, Types::ResourceReference.optional
      end
      
      # Security configuration
      class SecurityConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :ddos_protection, Types::Bool.default(true)
        attribute :waf_enabled, Types::Bool.default(false)
        attribute :waf_acl_ref, Types::ResourceReference.optional
        attribute :allowed_countries, Types::Array.of(Types::String).default([].freeze)
        attribute :blocked_countries, Types::Array.of(Types::String).default([].freeze)
        attribute :rate_limiting, Types::Hash.default({}.freeze)
        attribute :ip_allowlist, Types::Array.of(Types::String).default([].freeze)
        attribute :ip_blocklist, Types::Array.of(Types::String).default([].freeze)
      end
      
      # CloudFront distribution configuration
      class CloudFrontConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :price_class, Types::String.default('PriceClass_All')
        attribute :cache_behaviors, Types::Array.of(Types::Hash).default([].freeze)
        attribute :origin_shield_enabled, Types::Bool.default(false)
        attribute :origin_shield_region, Types::String.optional
        attribute :compress, Types::Bool.default(true)
        attribute :viewer_protocol_policy, Types::String.default('redirect-to-https')
        attribute :custom_error_responses, Types::Array.of(Types::Hash).default([].freeze)
      end
      
      # Main component attributes
      class GlobalTrafficManagerAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Core configuration
        attribute :manager_name, Types::String
        attribute :manager_description, Types::String.default("Global traffic management infrastructure")
        attribute :domain_name, Types::String
        attribute :certificate_arn, Types::String.optional
        
        # Endpoints to manage
        attribute :endpoints, Types::Array.of(EndpointConfig).constrained(min_size: 1)
        
        # Traffic policies
        attribute :traffic_policies, Types::Array.of(TrafficPolicyConfig).default([].freeze)
        attribute :default_policy, Types::String.enum('latency', 'weighted', 'geoproximity').default('latency')
        
        # Geo-routing configuration
        attribute :geo_routing, GeoRoutingConfig.default { GeoRoutingConfig.new({}) }
        
        # Performance optimization
        attribute :performance, PerformanceConfig.default { PerformanceConfig.new({}) }
        
        # Advanced routing
        attribute :advanced_routing, AdvancedRoutingConfig.default { AdvancedRoutingConfig.new({}) }
        
        # Observability
        attribute :observability, ObservabilityConfig.default { ObservabilityConfig.new({}) }
        
        # Security
        attribute :security, SecurityConfig.default { SecurityConfig.new({}) }
        
        # CloudFront configuration
        attribute :cloudfront, CloudFrontConfig.default { CloudFrontConfig.new({}) }
        
        # Global Accelerator configuration
        attribute :enable_global_accelerator, Types::Bool.default(true)
        attribute :global_accelerator_attributes, Types::Hash.default({}.freeze)
        
        # Route 53 configuration
        attribute :enable_route53_policies, Types::Bool.default(true)
        attribute :route53_hosted_zone_ref, Types::ResourceReference.optional
        
        # Multi-CDN strategy
        attribute :enable_multi_cdn, Types::Bool.default(false)
        attribute :cdn_providers, Types::Array.of(Types::String).default(['cloudfront'].freeze)
        
        # Tags
        attribute :tags, Types::Hash.default({}.freeze)
        
        # Custom validations
        def validate!
          errors = []
          
          # Validate endpoints
          endpoint_regions = endpoints.map(&:region)
          if endpoint_regions.uniq.length != endpoint_regions.length
            errors << "Duplicate regions found in endpoints"
          end
          
          # Validate weights sum to reasonable value for weighted routing
          if traffic_policies.any? { |p| p.policy_type == 'weighted' }
            total_weight = endpoints.sum(&:weight)
            if total_weight == 0
              errors << "Total endpoint weight must be greater than 0 for weighted routing"
            end
          end
          
          # Validate health check configuration
          traffic_policies.each do |policy|
            if policy.health_check_interval < 10 || policy.health_check_interval > 300
              errors << "Health check interval must be between 10 and 300 seconds"
            end
            
            if policy.health_check_timeout >= policy.health_check_interval
              errors << "Health check timeout must be less than interval"
            end
            
            if policy.unhealthy_threshold < 2 || policy.unhealthy_threshold > 10
              errors << "Unhealthy threshold must be between 2 and 10"
            end
          end
          
          # Validate geo-routing configuration
          if geo_routing.enabled
            if geo_routing.location_rules.empty?
              errors << "Geo-routing enabled but no location rules defined"
            end
            
            geo_routing.location_rules.each do |rule|
              unless rule[:location] && rule[:endpoint_region]
                errors << "Geo-routing rules must specify location and endpoint_region"
              end
            end
          end
          
          # Validate performance configuration
          if performance.flow_logs_enabled && !performance.flow_logs_s3_bucket
            errors << "Flow logs enabled but S3 bucket not specified"
          end
          
          if performance.connection_draining_timeout < 0 || performance.connection_draining_timeout > 3600
            errors << "Connection draining timeout must be between 0 and 3600 seconds"
          end
          
          # Validate security configuration
          if security.waf_enabled && !security.waf_acl_ref
            errors << "WAF enabled but no ACL reference provided"
          end
          
          if security.allowed_countries.any? && security.blocked_countries.any?
            overlap = security.allowed_countries & security.blocked_countries
            if overlap.any?
              errors << "Countries cannot be both allowed and blocked: #{overlap.join(', ')}"
            end
          end
          
          # Validate CloudFront configuration
          if cloudfront.enabled
            if cloudfront.origin_shield_enabled && !cloudfront.origin_shield_region
              errors << "Origin Shield enabled but region not specified"
            end
            
            valid_price_classes = ['PriceClass_All', 'PriceClass_200', 'PriceClass_100']
            unless valid_price_classes.include?(cloudfront.price_class)
              errors << "Invalid CloudFront price class"
            end
          end
          
          # Validate advanced routing
          if advanced_routing.canary_deployment.any?
            canary_percentage = advanced_routing.canary_deployment[:percentage] || 0
            if canary_percentage < 0 || canary_percentage > 50
              errors << "Canary deployment percentage must be between 0 and 50"
            end
          end
          
          # Validate multi-CDN configuration
          if enable_multi_cdn
            valid_providers = ['cloudfront', 'fastly', 'cloudflare', 'akamai']
            invalid_providers = cdn_providers - valid_providers
            if invalid_providers.any?
              errors << "Invalid CDN providers: #{invalid_providers.join(', ')}"
            end
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end