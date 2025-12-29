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
      # Security resources and WAF rules
      module Security
        def create_security_resources(name, attrs, resources, tags)
          return unless attrs.security.waf_enabled || attrs.security.ddos_protection

          security_resources = {}
          create_shield_protections(name, attrs, resources, tags, security_resources)
          create_waf_rules(name, attrs, tags, security_resources)
          resources[:security] = security_resources
        end

        private

        def create_shield_protections(name, attrs, resources, tags, security_resources)
          return unless attrs.security.ddos_protection

          create_ga_shield(name, resources, tags, security_resources) if attrs.enable_global_accelerator
          create_cf_shield(name, resources, tags, security_resources) if attrs.cloudfront.enabled
        end

        def create_ga_shield(name, resources, tags, security_resources)
          shield_ga_ref = aws_shield_protection(
            component_resource_name(name, :shield_ga),
            {
              name: "#{name}-ga-shield",
              resource_arn: resources[:global_accelerator][:accelerator].arn,
              tags: tags
            }
          )
          security_resources[:shield_ga] = shield_ga_ref
        end

        def create_cf_shield(name, resources, tags, security_resources)
          shield_cf_ref = aws_shield_protection(
            component_resource_name(name, :shield_cf),
            {
              name: "#{name}-cf-shield",
              resource_arn: resources[:cloudfront][:distribution].arn,
              tags: tags
            }
          )
          security_resources[:shield_cf] = shield_cf_ref
        end

        def create_waf_rules(name, attrs, tags, security_resources)
          return unless attrs.security.waf_enabled && !attrs.security.waf_acl_ref

          waf_resources = {}
          create_ip_allowlist(name, attrs, tags, waf_resources)
          rate_limit_rule = build_rate_limit_rule(attrs)
          create_web_acl(name, attrs, tags, waf_resources, rate_limit_rule)
          security_resources[:waf] = waf_resources
        end

        def create_ip_allowlist(name, attrs, tags, waf_resources)
          return unless attrs.security.ip_allowlist.any?

          ip_set_ref = aws_wafv2_ip_set(
            component_resource_name(name, :waf_ip_allowlist),
            {
              name: "#{name}-ip-allowlist",
              scope: 'CLOUDFRONT',
              ip_address_version: 'IPV4',
              addresses: attrs.security.ip_allowlist,
              tags: tags
            }
          )
          waf_resources[:ip_allowlist] = ip_set_ref
        end

        def build_rate_limit_rule(attrs)
          return nil unless attrs.security.rate_limiting.any?

          {
            name: 'RateLimitRule',
            priority: 1,
            statement: {
              rate_based_statement: {
                limit: attrs.security.rate_limiting[:limit] || 2000,
                aggregate_key_type: attrs.security.rate_limiting[:key_type] || 'IP'
              }
            },
            action: { block: {} },
            visibility_config: {
              sampled_requests_enabled: true,
              cloudwatch_metrics_enabled: true,
              metric_name: 'RateLimitRule'
            }
          }
        end

        def create_web_acl(name, attrs, tags, waf_resources, rate_limit_rule)
          rules = [rate_limit_rule]
          rules << build_ip_allowlist_rule(waf_resources) if attrs.security.ip_allowlist.any?

          web_acl_ref = aws_wafv2_web_acl(
            component_resource_name(name, :waf_acl),
            {
              name: "#{name}-web-acl",
              scope: 'CLOUDFRONT',
              default_action: { allow: {} },
              rule: rules.compact,
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "#{name}-waf-metrics",
                sampled_requests_enabled: true
              },
              tags: tags
            }
          )
          waf_resources[:web_acl] = web_acl_ref
        end

        def build_ip_allowlist_rule(waf_resources)
          {
            name: 'IPAllowlistRule',
            priority: 0,
            statement: {
              ip_set_reference_statement: {
                arn: waf_resources[:ip_allowlist].arn
              }
            },
            action: { allow: {} },
            visibility_config: {
              sampled_requests_enabled: true,
              cloudwatch_metrics_enabled: true,
              metric_name: 'IPAllowlistRule'
            }
          }
        end
      end
    end
  end
end
