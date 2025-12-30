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

module Pangea
  module Components
    module GlobalTrafficManager
      # Validation logic for GlobalTrafficManagerAttributes
      module Validators
        VALID_PRICE_CLASSES = %w[PriceClass_All PriceClass_200 PriceClass_100].freeze
        VALID_CDN_PROVIDERS = %w[cloudfront fastly cloudflare akamai].freeze

        def validate!
          errors = []
          errors.concat(validate_endpoints)
          errors.concat(validate_traffic_policies)
          errors.concat(validate_geo_routing)
          errors.concat(validate_performance)
          errors.concat(validate_security)
          errors.concat(validate_cloudfront)
          errors.concat(validate_advanced_routing)
          errors.concat(validate_multi_cdn)

          raise ArgumentError, errors.join(', ') unless errors.empty?

          true
        end

        private

        def validate_endpoints
          errors = []
          endpoint_regions = endpoints.map(&:region)
          if endpoint_regions.uniq.length != endpoint_regions.length
            errors << 'Duplicate regions found in endpoints'
          end

          if traffic_policies.any? { |p| p.policy_type == 'weighted' }
            total_weight = endpoints.sum(&:weight)
            errors << 'Total endpoint weight must be greater than 0 for weighted routing' if total_weight.zero?
          end
          errors
        end

        def validate_traffic_policies
          errors = []
          traffic_policies.each do |policy|
            errors.concat(validate_single_traffic_policy(policy))
          end
          errors
        end

        def validate_single_traffic_policy(policy)
          errors = []
          if policy.health_check_interval < 10 || policy.health_check_interval > 300
            errors << 'Health check interval must be between 10 and 300 seconds'
          end

          if policy.health_check_timeout >= policy.health_check_interval
            errors << 'Health check timeout must be less than interval'
          end

          if policy.unhealthy_threshold < 2 || policy.unhealthy_threshold > 10
            errors << 'Unhealthy threshold must be between 2 and 10'
          end
          errors
        end

        def validate_geo_routing
          errors = []
          return errors unless geo_routing.enabled

          errors << 'Geo-routing enabled but no location rules defined' if geo_routing.location_rules.empty?

          geo_routing.location_rules.each do |rule|
            unless rule[:location] && rule[:endpoint_region]
              errors << 'Geo-routing rules must specify location and endpoint_region'
            end
          end
          errors
        end

        def validate_performance
          errors = []
          if performance.flow_logs_enabled && !performance.flow_logs_s3_bucket
            errors << 'Flow logs enabled but S3 bucket not specified'
          end

          if performance.connection_draining_timeout < 0 || performance.connection_draining_timeout > 3600
            errors << 'Connection draining timeout must be between 0 and 3600 seconds'
          end
          errors
        end

        def validate_security
          errors = []
          if security.waf_enabled && !security.waf_acl_ref
            errors << 'WAF enabled but no ACL reference provided'
          end

          if security.allowed_countries.any? && security.blocked_countries.any?
            overlap = security.allowed_countries & security.blocked_countries
            errors << "Countries cannot be both allowed and blocked: #{overlap.join(', ')}" if overlap.any?
          end
          errors
        end

        def validate_cloudfront
          errors = []
          return errors unless cloudfront.enabled

          if cloudfront.origin_shield_enabled && !cloudfront.origin_shield_region
            errors << 'Origin Shield enabled but region not specified'
          end

          unless VALID_PRICE_CLASSES.include?(cloudfront.price_class)
            errors << 'Invalid CloudFront price class'
          end
          errors
        end

        def validate_advanced_routing
          errors = []
          return errors unless advanced_routing.canary_deployment.any?

          canary_percentage = advanced_routing.canary_deployment[:percentage] || 0
          if canary_percentage.negative? || canary_percentage > 50
            errors << 'Canary deployment percentage must be between 0 and 50'
          end
          errors
        end

        def validate_multi_cdn
          errors = []
          return errors unless enable_multi_cdn

          invalid_providers = cdn_providers - VALID_CDN_PROVIDERS
          if invalid_providers.any?
            errors << "Invalid CDN providers: #{invalid_providers.join(', ')}"
          end
          errors
        end
      end
    end
  end
end
