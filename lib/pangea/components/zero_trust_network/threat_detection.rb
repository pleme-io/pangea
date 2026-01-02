# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Threat detection resources for Zero Trust Network
      module ThreatDetection
        def create_threat_detection(name, attrs, resources)
          create_guardduty_detector(name, attrs, resources) if attrs.threat_protection[:enable_ids]
          create_waf(name, attrs, resources) if attrs.threat_protection[:enable_waf]
        end

        private

        def create_guardduty_detector(name, attrs, resources)
          detector_name = component_resource_name(name, :guardduty)
          resources[:guardduty] = aws_guardduty_detector(detector_name, {
            enable: true,
            finding_publishing_frequency: 'FIFTEEN_MINUTES',
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end

        def create_waf(name, attrs, resources)
          waf_name = component_resource_name(name, :waf)
          resources[:waf] = aws_wafv2_web_acl(waf_name, {
            name: "zt-waf-#{name}",
            scope: 'REGIONAL',
            default_action: { allow: {} },
            rules: waf_rules(attrs),
            visibility_config: {
              cloudwatch_metrics_enabled: true,
              metric_name: "zt-waf-#{name}",
              sampled_requests_enabled: true
            },
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end

        def waf_rules(_attrs)
          [
            common_rule_set,
            rate_limit_rule
          ]
        end

        def common_rule_set
          {
            name: 'AWSManagedRulesCommonRuleSet',
            priority: 1,
            override_action: { none: {} },
            statement: {
              managed_rule_group_statement: {
                vendor_name: 'AWS',
                name: 'AWSManagedRulesCommonRuleSet'
              }
            },
            visibility_config: {
              cloudwatch_metrics_enabled: true,
              metric_name: 'CommonRuleSetMetric',
              sampled_requests_enabled: true
            }
          }
        end

        def rate_limit_rule
          {
            name: 'RateLimitRule',
            priority: 2,
            action: { block: {} },
            statement: {
              rate_based_statement: {
                limit: 2000,
                aggregate_key_type: 'IP'
              }
            },
            visibility_config: {
              cloudwatch_metrics_enabled: true,
              metric_name: 'RateLimitMetric',
              sampled_requests_enabled: true
            }
          }
        end
      end
    end
  end
end
