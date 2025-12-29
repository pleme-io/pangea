# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Monitoring and alerting for Zero Trust Network
      module Monitoring
        def create_monitoring_alarms(name, attrs, resources)
          return unless attrs.monitoring_config[:create_alarms]

          create_access_denied_alarm(name, attrs, resources)
          create_policy_violation_alarm(name, attrs, resources)
          create_suspicious_activity_alarm(name, attrs, resources)
        end

        private

        def create_access_denied_alarm(name, attrs, resources)
          alarm_name = component_resource_name(name, :access_denied_alarm)
          resources[:alarms][:access_denied] = aws_cloudwatch_metric_alarm(alarm_name, {
            alarm_name: "zt-access-denied-#{name}",
            alarm_description: 'Alert on excessive access denials',
            metric_name: 'AccessDenied',
            namespace: 'AWS/VerifiedAccess',
            statistic: 'Sum',
            period: 300,
            evaluation_periods: 2,
            threshold: attrs.verification_settings[:max_failed_attempts],
            comparison_operator: 'GreaterThanThreshold',
            dimensions: {
              VerifiedAccessInstanceId: resources[:verified_access_instance].id
            },
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end

        def create_policy_violation_alarm(name, attrs, resources)
          return unless attrs.monitoring_config[:alert_on_policy_violations]

          alarm_name = component_resource_name(name, :policy_violation_alarm)
          resources[:alarms][:policy_violation] = aws_cloudwatch_metric_alarm(alarm_name, {
            alarm_name: "zt-policy-violation-#{name}",
            alarm_description: 'Alert on policy violations',
            metric_name: 'PolicyViolations',
            namespace: 'Custom/ZeroTrust',
            statistic: 'Sum',
            period: 300,
            evaluation_periods: 1,
            threshold: 1,
            comparison_operator: 'GreaterThanOrEqualToThreshold',
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end

        def create_suspicious_activity_alarm(name, attrs, resources)
          return unless attrs.monitoring_config[:alert_on_suspicious_activity]

          alarm_name = component_resource_name(name, :suspicious_activity_alarm)
          resources[:alarms][:suspicious_activity] = aws_cloudwatch_metric_alarm(alarm_name, {
            alarm_name: "zt-suspicious-activity-#{name}",
            alarm_description: 'Alert on suspicious activity patterns',
            metric_name: 'SuspiciousActivity',
            namespace: 'Custom/ZeroTrust',
            statistic: 'Sum',
            period: 300,
            evaluation_periods: 1,
            threshold: 1,
            comparison_operator: 'GreaterThanOrEqualToThreshold',
            tags: component_tags('zero_trust_network', name, attrs.tags)
          })
        end
      end
    end
  end
end
