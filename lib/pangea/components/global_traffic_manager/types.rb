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

require_relative 'types/endpoint_config'
require_relative 'types/traffic_policy_config'
require_relative 'types/geo_routing_config'
require_relative 'types/advanced_routing_config'
require_relative 'types/performance_config'
require_relative 'types/observability_config'
require_relative 'types/security_config'
require_relative 'types/cloudfront_config'
require_relative 'types/validators'

module Pangea
  module Components
    module GlobalTrafficManager
      # Main component attributes
      class GlobalTrafficManagerAttributes < Dry::Struct
        include Validators
        transform_keys(&:to_sym)

        # Core configuration
        attribute :manager_name, Types::String
        attribute :manager_description, Types::String.default('Global traffic management infrastructure')
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
      end
    end
  end
end
