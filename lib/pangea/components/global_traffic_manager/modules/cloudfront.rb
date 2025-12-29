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
      # CloudFront distribution resources
      module Cloudfront
        def create_cloudfront_resources(name, attrs, resources, tags)
          return unless attrs.cloudfront.enabled

          resources[:cloudfront] = create_cloudfront_distribution(name, attrs, tags)
        end

        private

        def create_cloudfront_distribution(name, attrs, tags)
          cf_resources = {}

          oai_ref = aws_cloudfront_origin_access_identity(
            component_resource_name(name, :cf_oai),
            { comment: "OAI for #{attrs.manager_name}" }
          )
          cf_resources[:oai] = oai_ref

          distribution_ref = aws_cloudfront_distribution(
            component_resource_name(name, :cf_distribution),
            build_distribution_config(name, attrs, tags)
          )
          cf_resources[:distribution] = distribution_ref

          cf_resources
        end

        def build_distribution_config(name, attrs, tags)
          {
            comment: attrs.manager_description,
            enabled: true,
            is_ipv6_enabled: true,
            price_class: attrs.cloudfront.price_class,
            aliases: [attrs.domain_name],
            viewer_certificate: build_viewer_certificate(attrs),
            origin: build_origins(attrs),
            default_cache_behavior: build_default_cache_behavior(name, attrs, tags),
            ordered_cache_behavior: build_ordered_cache_behaviors(attrs),
            restrictions: build_restrictions(attrs),
            web_acl_id: attrs.security.waf_acl_ref&.arn,
            logging_config: build_logging_config(attrs),
            custom_error_response: build_custom_error_responses(attrs),
            tags: tags
          }.compact
        end

        def build_viewer_certificate(attrs)
          if attrs.certificate_arn
            {
              acm_certificate_arn: attrs.certificate_arn,
              ssl_support_method: 'sni-only',
              minimum_protocol_version: 'TLSv1.2_2021'
            }
          else
            { cloudfront_default_certificate: true }
          end
        end

        def build_origins(attrs)
          attrs.endpoints.map do |endpoint|
            {
              domain_name: endpoint.endpoint_id,
              origin_id: "origin-#{endpoint.region}",
              custom_origin_config: build_custom_origin_config(attrs, endpoint),
              origin_shield: build_origin_shield(attrs, endpoint),
              custom_header: build_custom_headers(attrs)
            }.compact
          end
        end

        def build_custom_origin_config(attrs, _endpoint)
          {
            http_port: 80,
            https_port: 443,
            origin_protocol_policy: 'https-only',
            origin_ssl_protocols: ['TLSv1.2'],
            origin_keepalive_timeout: attrs.performance.idle_timeout,
            origin_read_timeout: 30
          }
        end

        def build_origin_shield(attrs, endpoint)
          return nil unless attrs.cloudfront.origin_shield_enabled

          {
            enabled: true,
            origin_shield_region: attrs.cloudfront.origin_shield_region || endpoint.region
          }
        end

        def build_custom_headers(attrs)
          attrs.advanced_routing.custom_headers.map do |header|
            { name: header[:name], value: header[:value] }
          end
        end

        def build_default_cache_behavior(name, attrs, tags)
          {
            target_origin_id: "origin-#{attrs.endpoints.first.region}",
            viewer_protocol_policy: attrs.cloudfront.viewer_protocol_policy,
            allowed_methods: %w[GET HEAD OPTIONS PUT POST PATCH DELETE],
            cached_methods: %w[GET HEAD OPTIONS],
            forwarded_values: {
              query_string: true,
              headers: ['*'],
              cookies: { forward: 'all' }
            },
            compress: attrs.cloudfront.compress,
            min_ttl: 0,
            default_ttl: 86_400,
            max_ttl: 31_536_000,
            lambda_function_association: create_edge_functions(name, attrs, tags)
          }
        end

        def build_ordered_cache_behaviors(attrs)
          attrs.cloudfront.cache_behaviors.map do |behavior|
            {
              path_pattern: behavior[:path_pattern],
              target_origin_id: behavior[:origin_id] || "origin-#{attrs.endpoints.first.region}",
              viewer_protocol_policy: behavior[:viewer_protocol_policy] || attrs.cloudfront.viewer_protocol_policy,
              allowed_methods: behavior[:allowed_methods] || %w[GET HEAD],
              cached_methods: behavior[:cached_methods] || %w[GET HEAD],
              forwarded_values: {
                query_string: behavior[:forward_query_string] || false,
                headers: behavior[:forward_headers] || [],
                cookies: { forward: behavior[:forward_cookies] || 'none' }
              },
              min_ttl: behavior[:min_ttl] || 0,
              default_ttl: behavior[:default_ttl] || 300,
              max_ttl: behavior[:max_ttl] || 86_400,
              compress: behavior[:compress] || attrs.cloudfront.compress
            }
          end
        end

        def build_restrictions(attrs)
          {
            geo_restriction: {
              restriction_type: attrs.security.blocked_countries.any? ? 'blacklist' : 'none',
              locations: attrs.security.blocked_countries
            }
          }
        end

        def build_logging_config(attrs)
          return nil unless attrs.observability.access_logs_enabled

          {
            bucket: "#{attrs.performance.flow_logs_s3_bucket}.s3.amazonaws.com",
            prefix: "#{attrs.performance.flow_logs_s3_prefix}cloudfront/",
            include_cookies: true
          }
        end

        def build_custom_error_responses(attrs)
          attrs.cloudfront.custom_error_responses.map do |error_response|
            {
              error_code: error_response[:error_code],
              response_code: error_response[:response_code],
              response_page_path: error_response[:response_page_path],
              error_caching_min_ttl: error_response[:caching_min_ttl] || 300
            }
          end
        end
      end
    end
  end
end
