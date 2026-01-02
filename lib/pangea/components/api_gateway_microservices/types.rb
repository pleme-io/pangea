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

require 'dry-struct'
require 'pangea/resources/types'
require_relative 'types/core'
require_relative 'types/policy'
require_relative 'types/endpoint'

module Pangea
  module Components
    module ApiGatewayMicroservices
      # Main component attributes
      class ApiGatewayMicroservicesAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Core configuration
        attribute :api_name, Types::String
        attribute :api_description, Types::String.default('Microservices API Gateway')
        attribute :stage_name, Types::String.default('prod')
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

          validate_service_endpoints(errors)
          validate_rate_limiting(errors)
          validate_cache_configuration(errors)
          validate_cors_configuration(errors)
          validate_private_endpoint(errors)

          raise ArgumentError, errors.join(', ') unless errors.empty?

          true
        end

        private

        def validate_service_endpoints(errors)
          endpoint_names = service_endpoints.map(&:name)
          errors << 'Service endpoint names must be unique' if endpoint_names.uniq.length != endpoint_names.length

          base_paths = service_endpoints.map(&:base_path)
          errors << 'Service base paths must be unique' if base_paths.uniq.length != base_paths.length

          service_endpoints.each do |endpoint|
            validate_endpoint_methods(endpoint, errors)
            validate_vpc_link_requirements(endpoint, errors)
          end
        end

        def validate_endpoint_methods(endpoint, errors)
          paths = endpoint.methods.map(&:path)
          return if paths.uniq.length == paths.length

          errors << "Method paths must be unique within service endpoint: #{endpoint.name}"
        end

        def validate_vpc_link_requirements(endpoint, errors)
          return unless endpoint.integration.connection_type == 'VPC_LINK'
          return if endpoint.vpc_link_ref || endpoint.integration.connection_id

          errors << "VPC_LINK connection type requires vpc_link_ref or connection_id for endpoint: #{endpoint.name}"
        end

        def validate_rate_limiting(errors)
          return unless rate_limit.enabled

          errors << 'Rate limit must be greater than 0' if rate_limit.rate_limit <= 0
          errors << 'Burst limit must be greater than or equal to rate limit' if rate_limit.burst_limit < rate_limit.rate_limit
        end

        def validate_cache_configuration(errors)
          return unless cache_cluster_enabled

          valid_sizes = %w[0.5 1.6 6.1 13.5 28.4 58.2 118 237]
          return if valid_sizes.include?(cache_cluster_size)

          errors << "Invalid cache cluster size: #{cache_cluster_size}"
        end

        def validate_cors_configuration(errors)
          return unless cors.enabled && cors.allow_credentials && cors.allow_origins.include?('*')

          errors << 'Cannot use wildcard origins with credentials'
        end

        def validate_private_endpoint(errors)
          return unless endpoint_type == 'PRIVATE' && vpc_endpoint_ids.empty?

          errors << 'Private endpoints require at least one VPC endpoint ID'
        end
      end
    end
  end
end
