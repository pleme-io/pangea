# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # API Gateway Stage attributes with validation
        class ApiGatewayStageAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :rest_api_id, Pangea::Resources::Types::String
          attribute :deployment_id, Pangea::Resources::Types::String
          attribute :stage_name, Pangea::Resources::Types::String
          
          # Stage configuration
          attribute :description, Pangea::Resources::Types::String.optional.default(nil)
          attribute :documentation_version, Pangea::Resources::Types::String.optional.default(nil)
          
          # Caching
          attribute :cache_cluster_enabled, Pangea::Resources::Types::Bool.default(false)
          attribute :cache_cluster_size, Pangea::Resources::Types::String.constrained(included_in: ['0.5', '1.6', '6.1', '13.5', '28.4', '58.2', '118', '237']).optional.default(nil)
          
          # Stage variables
          attribute :variables, Pangea::Resources::Types::Hash.map(
            Pangea::Resources::Types::String, Pangea::Resources::Types::String
          ).default({}.freeze)
          
          # Logging and monitoring
          attribute :xray_tracing_enabled, Pangea::Resources::Types::Bool.default(false)
          
          # Access logging
          attribute :access_log_settings, Pangea::Resources::Types::Hash.optional.default(nil)
          
          # Throttling
          attribute :throttle_burst_limit, Pangea::Resources::Types::Coercible::Integer.optional.default(nil)
          attribute :throttle_rate_limit, Pangea::Resources::Types::Coercible::Float.optional.default(nil)
          
          # Method settings (per-method configuration)
          attribute :method_settings, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::Hash).default([].freeze)
          
          # Canary settings
          attribute :canary_settings, Pangea::Resources::Types::Hash.optional.default(nil)
          
          # Client certificate
          attribute :client_certificate_id, Pangea::Resources::Types::String.optional.default(nil)
          
          # Tags
          attribute :tags, Pangea::Resources::Types::AwsTags
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate stage name
            if attrs[:stage_name]
              unless attrs[:stage_name].match?(/^[a-zA-Z0-9_-]+$/)
                raise Dry::Struct::Error, "Stage name must contain only alphanumeric characters, underscores, and dashes"
              end
              
              # Check reserved names
              if ['test'].include?(attrs[:stage_name].downcase)
                raise Dry::Struct::Error, "Stage name '#{attrs[:stage_name]}' is reserved"
              end
            end
            
            # Validate cache cluster size is provided when cache is enabled
            if attrs[:cache_cluster_enabled] && attrs[:cache_cluster_size].nil?
              raise Dry::Struct::Error, "cache_cluster_size must be specified when cache_cluster_enabled is true"
            end
            
            # Validate throttling limits
            if attrs[:throttle_rate_limit] && attrs[:throttle_rate_limit] < 0
              raise Dry::Struct::Error, "throttle_rate_limit must be non-negative"
            end
            
            if attrs[:throttle_burst_limit] && attrs[:throttle_burst_limit] < 0
              raise Dry::Struct::Error, "throttle_burst_limit must be non-negative"
            end
            
            # Validate access log settings
            if attrs[:access_log_settings]
              unless attrs[:access_log_settings].key?(:destination_arn)
                raise Dry::Struct::Error, "access_log_settings must include destination_arn"
              end
              unless attrs[:access_log_settings].key?(:format)
                raise Dry::Struct::Error, "access_log_settings must include format"
              end
            end
            
            # Validate method settings
            if attrs[:method_settings]
              attrs[:method_settings].each do |method_setting|
                # Validate required fields
                unless method_setting.key?(:resource_path) && method_setting.key?(:http_method)
                  raise Dry::Struct::Error, "Method setting must include resource_path and http_method"
                end
                
                # Validate resource path format
                unless method_setting[:resource_path].start_with?('/')
                  raise Dry::Struct::Error, "Method setting resource_path must start with '/'"
                end
                
                # Validate HTTP method
                valid_methods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH', 'ANY', '*']
                unless valid_methods.include?(method_setting[:http_method])
                  raise Dry::Struct::Error, "Invalid HTTP method: #{method_setting[:http_method]}"
                end
                
                # Validate logging level
                if method_setting[:logging_level]
                  unless ['OFF', 'ERROR', 'INFO'].include?(method_setting[:logging_level])
                    raise Dry::Struct::Error, "Invalid logging level: #{method_setting[:logging_level]}"
                  end
                end
                
                # Validate cache TTL
                if method_setting[:cache_ttl_in_seconds] && 
                   (method_setting[:cache_ttl_in_seconds] < 0 || method_setting[:cache_ttl_in_seconds] > 3600)
                  raise Dry::Struct::Error, "cache_ttl_in_seconds must be between 0 and 3600"
                end
              end
            end
            
            # Validate canary settings
            if attrs[:canary_settings]
              percent = attrs[:canary_settings][:percent_traffic].to_f
              if percent < 0.0 || percent > 100.0
                raise Dry::Struct::Error, "Canary traffic percentage must be between 0.0 and 100.0"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_caching?
            cache_cluster_enabled
          end
          
          def has_access_logging?
            !access_log_settings.nil?
          end
          
          def has_canary?
            !canary_settings.nil? && canary_settings[:percent_traffic].to_f > 0
          end
          
          def has_throttling?
            !throttle_rate_limit.nil? || !throttle_burst_limit.nil?
          end
          
          def has_method_settings?
            !method_settings.empty?
          end
          
          def estimated_monthly_cost
            cost = 0.0
            
            # Cache cluster costs (per hour)
            if cache_cluster_enabled && cache_cluster_size
              cache_costs = {
                '0.5' => 0.02,
                '1.6' => 0.038,
                '6.1' => 0.2,
                '13.5' => 0.415,
                '28.4' => 0.83,
                '58.2' => 1.66,
                '118' => 3.32,
                '237' => 6.64
              }
              
              cost += (cache_costs[cache_cluster_size] || 0) * 24 * 30  # Monthly cost
            end
            
            cost
          end
          
          # Common access log formats
          def self.common_log_formats
            {
              # Standard format with all fields
              standard: '$context.requestId $context.requestTime $context.httpMethod $context.path $context.status $context.responseLength',
              
              # Extended format with more details
              extended: '$context.requestId $context.extendedRequestId $context.requestTime $context.httpMethod $context.path $context.status $context.responseLength $context.error.message $context.error.messageString',
              
              # JSON format
              json: '{"requestId":"$context.requestId","requestTime":"$context.requestTime","httpMethod":"$context.httpMethod","path":"$context.path","status":"$context.status","responseLength":"$context.responseLength","sourceIp":"$context.identity.sourceIp","userAgent":"$context.identity.userAgent"}',
              
              # Custom format with auth info
              auth_detailed: '$context.requestId $context.requestTime $context.httpMethod $context.path $context.status $context.authorizer.principalId $context.authorizer.claims.sub'
            }
          end
          
          # Common method paths
          def self.common_method_paths
            {
              all_methods: '/*/*',           # All resources and methods
              root_all: '/*',               # Root level all methods
              specific_all: '/users/*',     # All methods on /users
              specific_method: '/users/GET' # Specific method on resource
            }
          end
        end
      end
    end
  end
end