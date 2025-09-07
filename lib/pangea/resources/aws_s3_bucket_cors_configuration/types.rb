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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # S3 CORS rule configuration
      class CorsRule < Dry::Struct
        # Unique identifier for the rule (optional)
        attribute :id, Resources::Types::String.optional
        
        # HTTP methods allowed for CORS requests
        attribute :allowed_methods, Resources::Types::Array.of(
          Types::String.enum("GET", "PUT", "POST", "DELETE", "HEAD")
        ).constrained(min_size: 1)
        
        # Origins allowed to make CORS requests
        attribute :allowed_origins, Resources::Types::Array.of(Types::String).constrained(min_size: 1)
        
        # Headers allowed in CORS requests (optional)
        attribute :allowed_headers, Resources::Types::Array.of(Types::String).optional
        
        # Headers exposed to client in CORS response (optional)
        attribute :expose_headers, Resources::Types::Array.of(Types::String).optional
        
        # Maximum time in seconds for browser to cache preflight response (optional)
        attribute :max_age_seconds, Resources::Types::Integer.constrained(gteq: 0, lteq: 2147483647).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate that if max_age_seconds is specified, it's reasonable
          if attrs.max_age_seconds && attrs.max_age_seconds > 86400 * 7 # 7 days
            warn "max_age_seconds #{attrs.max_age_seconds} is very high (>7 days). Consider a lower value for security."
          end
          
          # Validate origin patterns
          attrs.allowed_origins.each do |origin|
            if origin == "*" && attrs.allowed_origins.length > 1
              raise Dry::Struct::Error, "When using wildcard '*' origin, it must be the only allowed origin"
            end
          end
          
          attrs
        end

        # Helper methods
        def allows_method?(method)
          allowed_methods.include?(method.upcase)
        end

        def allows_origin?(origin)
          allowed_origins.include?(origin) || allowed_origins.include?("*")
        end

        def allows_all_origins?
          allowed_origins.include?("*")
        end

        def has_headers?
          !allowed_headers.nil? && allowed_headers.any?
        end

        def exposes_headers?
          !expose_headers.nil? && expose_headers.any?
        end

        def has_max_age?
          !max_age_seconds.nil?
        end

        def method_count
          allowed_methods.length
        end

        def origin_count
          allowed_origins.length
        end
      end

      # Type-safe attributes for AWS S3 Bucket CORS Configuration
      class S3BucketCorsConfigurationAttributes < Dry::Struct
        # S3 bucket to apply CORS configuration to
        attribute :bucket, Resources::Types::String
        
        # Expected bucket owner (optional)
        attribute :expected_bucket_owner, Resources::Types::String.optional
        
        # CORS rules (1-100 rules maximum)
        attribute :cors_rule, Resources::Types::Array.of(CorsRule).constrained(min_size: 1, max_size: 100)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate unique rule IDs if present
          rule_ids = attrs.cors_rule.filter_map(&:id).compact
          if rule_ids.uniq.length != rule_ids.length
            raise Dry::Struct::Error, "CORS rule IDs must be unique when specified"
          end
          
          # Warn about wildcard origins with credentials
          attrs.cors_rule.each_with_index do |rule, index|
            if rule.allows_all_origins? && rule.allows_method?("POST")
              warn "CORS rule #{index + 1}: Allowing all origins (*) with POST method may be insecure"
            end
          end
          
          attrs
        end

        # Helper methods
        def total_rules_count
          cors_rule.length
        end

        def rules_with_wildcards
          cors_rule.select(&:allows_all_origins?)
        end

        def rules_allowing_method(method)
          cors_rule.select { |rule| rule.allows_method?(method) }
        end

        def rules_with_max_age
          cors_rule.select(&:has_max_age?)
        end

        def rules_exposing_headers
          cors_rule.select(&:exposes_headers?)
        end

        def max_max_age
          max_ages = cors_rule.filter_map(&:max_age_seconds).compact
          max_ages.any? ? max_ages.max : nil
        end

        def all_allowed_methods
          cors_rule.flat_map(&:allowed_methods).uniq.sort
        end

        def all_allowed_origins
          cors_rule.flat_map(&:allowed_origins).uniq
        end
      end
    end
      end
    end
  end
end