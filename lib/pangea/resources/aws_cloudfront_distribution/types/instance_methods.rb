# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module CloudFrontDistributionMethods
          def total_origins_count = origin.size
          def total_behaviors_count = 1 + ordered_cache_behavior.size
          def has_custom_ssl? = viewer_certificate[:acm_certificate_arn].to_s != '' || viewer_certificate[:iam_certificate_id].to_s != ''
          def uses_cloudfront_ssl? = viewer_certificate[:cloudfront_default_certificate] == true
          def has_custom_domain? = aliases.any?
          def has_geographic_restrictions? = restrictions.dig(:geo_restriction, :restriction_type) != 'none'
          def has_custom_error_pages? = custom_error_response.any?
          def has_origin_shield? = origin.any? { |o| o[:origin_shield]&.dig(:enabled) == true }
          def supports_http2? = http_version == 'http2'
          def ipv6_enabled? = is_ipv6_enabled

          def has_lambda_at_edge?
            all_behaviors = [default_cache_behavior] + ordered_cache_behavior
            all_behaviors.any? { |b| b[:lambda_function_association]&.any? }
          end

          def has_cloudfront_functions?
            all_behaviors = [default_cache_behavior] + ordered_cache_behavior
            all_behaviors.any? { |b| b[:function_association]&.any? }
          end

          def estimated_cost_tier
            case price_class
            when 'PriceClass_100' then 'low'
            when 'PriceClass_200' then 'medium'
            else 'high'
            end
          end

          def s3_origins_count = origin.count { |o| o[:s3_origin_config] }
          def custom_origins_count = origin.count { |o| o[:custom_origin_config] }
          def primary_domain = has_custom_domain? ? aliases.first : 'generated.cloudfront.net'

          def security_profile
            factors = []
            factors << 'https_only' if default_cache_behavior[:viewer_protocol_policy] == 'https-only'
            factors << 'custom_ssl' if has_custom_ssl?
            factors << 'waf_enabled' if web_acl_id.to_s != ''
            factors << 'geo_restricted' if has_geographic_restrictions?
            case factors.size
            when 0..1 then 'basic'
            when 2..3 then 'enhanced'
            else 'maximum'
            end
          end
        end
      end
    end
  end
end
