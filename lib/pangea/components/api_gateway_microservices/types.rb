# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module ApiGatewayMicroservices
      # API method configuration
      class ApiMethodConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :path, Types::String
        attribute :method, Types::String.enum('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS', 'HEAD', 'ANY')
        attribute :authorization, Types::String.default("NONE")
        attribute :api_key_required, Types::Bool.default(false)
        attribute :request_validator, Types::String.optional
        attribute :request_models, Types::Hash.default({}.freeze)
        attribute :request_parameters, Types::Hash.default({}.freeze)
      end
      
      # Service integration configuration
      class ServiceIntegration < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :type, Types::String.enum('HTTP', 'HTTP_PROXY', 'AWS', 'AWS_PROXY', 'MOCK')
        attribute :uri, Types::String
        attribute :connection_type, Types::String.enum('INTERNET', 'VPC_LINK').default('INTERNET')
        attribute :connection_id, Types::String.optional
        attribute :http_method, Types::String.default('ANY')
        attribute :timeout_milliseconds, Types::Integer.default(29000)
        attribute :content_handling, Types::String.enum('CONVERT_TO_BINARY', 'CONVERT_TO_TEXT').optional
        attribute :passthrough_behavior, Types::String.default('WHEN_NO_MATCH')
        attribute :cache_key_parameters, Types::Array.of(Types::String).default([].freeze)
        attribute :cache_namespace, Types::String.optional
      end
      
      # Request/Response transformation
      class TransformationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :request_templates, Types::Hash.default({}.freeze)
        attribute :response_templates, Types::Hash.default({}.freeze)
        attribute :response_parameters, Types::Hash.default({}.freeze)
        attribute :response_models, Types::Hash.default({}.freeze)
      end
      
      # Rate limiting configuration
      class RateLimitConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :burst_limit, Types::Integer.default(5000)
        attribute :rate_limit, Types::Float.default(10000.0)
        attribute :quota_limit, Types::Integer.optional
        attribute :quota_period, Types::String.enum('DAY', 'WEEK', 'MONTH').optional
      end
      
      # API versioning configuration
      class VersioningConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :strategy, Types::String.enum('PATH', 'HEADER', 'QUERY').default('PATH')
        attribute :default_version, Types::String.default('v1')
        attribute :versions, Types::Array.of(Types::String).default(['v1'].freeze)
        attribute :header_name, Types::String.default('X-API-Version')
        attribute :query_param, Types::String.default('version')
      end
      
      # CORS configuration
      class CorsConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :allow_origins, Types::Array.of(Types::String).default(['*'].freeze)
        attribute :allow_methods, Types::Array.of(Types::String).default(['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'].freeze)
        attribute :allow_headers, Types::Array.of(Types::String).default(['Content-Type', 'Authorization', 'X-API-Key'].freeze)
        attribute :expose_headers, Types::Array.of(Types::String).default([].freeze)
        attribute :max_age, Types::Integer.default(86400)
        attribute :allow_credentials, Types::Bool.default(false)
      end
      
      # Service endpoint configuration
      class ServiceEndpoint < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Types::String
        attribute :base_path, Types::String
        attribute :methods, Types::Array.of(ApiMethodConfig)
        attribute :integration, ServiceIntegration
        attribute :transformation, TransformationConfig.default { TransformationConfig.new({}) }
        attribute :rate_limit_override, RateLimitConfig.optional
        attribute :vpc_link_ref, Types::ResourceReference.optional
        attribute :nlb_ref, Types::ResourceReference.optional
      end
      
      # API documentation configuration
      class DocumentationConfig < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :enabled, Types::Bool.default(true)
        attribute :title, Types::String
        attribute :description, Types::String
        attribute :version, Types::String.default('1.0.0')
        attribute :contact_email, Types::String.optional
        attribute :license_name, Types::String.default('Apache 2.0')
        attribute :license_url, Types::String.default('https://www.apache.org/licenses/LICENSE-2.0.html')
      end
      
      # Main component attributes
      class ApiGatewayMicroservicesAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Core configuration
        attribute :api_name, Types::String
        attribute :api_description, Types::String.default("Microservices API Gateway")
        attribute :stage_name, Types::String.default("prod")
        attribute :deployment_description, Types::String.optional
        
        # Service endpoints
        attribute :service_endpoints, Types::Array.of(ServiceEndpoint).constrained(min_size: 1)
        
        # API configuration
        attribute :endpoint_type, Types::String.enum('EDGE', 'REGIONAL', 'PRIVATE').default('REGIONAL')
        attribute :vpc_endpoint_ids, Types::Array.of(Types::String).default([].freeze)
        attribute :binary_media_types, Types::Array.of(Types::String).default(['application/octet-stream', 'image/*'].freeze)
        attribute :minimum_compression_size, Types::Integer.optional
        
        # Rate limiting
        attribute :rate_limit, RateLimitConfig.default { RateLimitConfig.new({}) }
        
        # API versioning
        attribute :versioning, VersioningConfig.default { VersioningConfig.new({}) }
        
        # CORS configuration
        attribute :cors, CorsConfig.default { CorsConfig.new({}) }
        
        # Authorization
        attribute :authorizer_ref, Types::ResourceReference.optional
        attribute :api_key_source, Types::String.enum('HEADER', 'AUTHORIZER').default('HEADER')
        attribute :require_api_key, Types::Bool.default(false)
        
        # Caching
        attribute :cache_cluster_enabled, Types::Bool.default(false)
        attribute :cache_cluster_size, Types::String.default('0.5')
        attribute :cache_ttl, Types::Integer.default(300)
        
        # Logging and monitoring
        attribute :access_log_destination_arn, Types::String.optional
        attribute :access_log_format, Types::String.optional
        attribute :xray_tracing_enabled, Types::Bool.default(true)
        attribute :metrics_enabled, Types::Bool.default(true)
        attribute :logging_level, Types::String.enum('OFF', 'ERROR', 'INFO').default('ERROR')
        attribute :data_trace_enabled, Types::Bool.default(false)
        
        # WAF protection
        attribute :waf_acl_ref, Types::ResourceReference.optional
        
        # Documentation
        attribute :documentation, DocumentationConfig.optional
        
        # Tags
        attribute :tags, Types::Hash.default({}.freeze)
        
        # Custom validations
        def validate!
          errors = []
          
          # Validate service endpoints
          endpoint_names = service_endpoints.map(&:name)
          if endpoint_names.uniq.length != endpoint_names.length
            errors << "Service endpoint names must be unique"
          end
          
          # Validate base paths
          base_paths = service_endpoints.map(&:base_path)
          if base_paths.uniq.length != base_paths.length
            errors << "Service base paths must be unique"
          end
          
          # Validate method paths within each service
          service_endpoints.each do |endpoint|
            paths = endpoint.methods.map(&:path)
            if paths.uniq.length != paths.length
              errors << "Method paths must be unique within service endpoint: #{endpoint.name}"
            end
            
            # Validate VPC link requirements
            if endpoint.integration.connection_type == 'VPC_LINK'
              unless endpoint.vpc_link_ref || endpoint.integration.connection_id
                errors << "VPC_LINK connection type requires vpc_link_ref or connection_id for endpoint: #{endpoint.name}"
              end
            end
          end
          
          # Validate rate limiting
          if rate_limit.enabled
            if rate_limit.rate_limit <= 0
              errors << "Rate limit must be greater than 0"
            end
            
            if rate_limit.burst_limit < rate_limit.rate_limit
              errors << "Burst limit must be greater than or equal to rate limit"
            end
          end
          
          # Validate cache configuration
          if cache_cluster_enabled
            valid_sizes = ['0.5', '1.6', '6.1', '13.5', '28.4', '58.2', '118', '237']
            unless valid_sizes.include?(cache_cluster_size)
              errors << "Invalid cache cluster size: #{cache_cluster_size}"
            end
          end
          
          # Validate CORS configuration
          if cors.enabled && cors.allow_credentials
            if cors.allow_origins.include?('*')
              errors << "Cannot use wildcard origins with credentials"
            end
          end
          
          # Validate private endpoint configuration
          if endpoint_type == 'PRIVATE' && vpc_endpoint_ids.empty?
            errors << "Private endpoints require at least one VPC endpoint ID"
          end
          
          raise ArgumentError, errors.join(", ") unless errors.empty?
          
          true
        end
      end
    end
  end
end