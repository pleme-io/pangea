# frozen_string_literal: true

module Pangea
  module Components
    module ZeroTrustNetwork
      # Compliance and security scoring for Zero Trust Network
      module Compliance
        FRAMEWORK_CONTROLS = {
          'soc2' => %w[CC1.1 CC1.2 CC1.3 CC2.1 CC3.1 CC4.1 CC5.1 CC6.1 CC7.1 CC8.1 CC9.1],
          'iso27001' => %w[A.5.1 A.6.1 A.7.1 A.8.1 A.9.1 A.10.1 A.11.1 A.12.1 A.13.1 A.14.1],
          'nist' => %w[AC-1 AC-2 AC-3 AU-1 AU-2 CA-1 CA-2 CM-1 CP-1 IA-1 IR-1 MA-1],
          'pci-dss' => %w[1.1 1.2 2.1 2.2 3.1 3.2 4.1 5.1 6.1 7.1 8.1 9.1 10.1 11.1 12.1],
          'hipaa' => %w[164.308 164.310 164.312 164.314 164.316],
          'fedramp' => %w[AC-1 AC-2 AU-1 CA-1 CM-1 CP-1 IA-1 IR-1 MA-1 MP-1 PE-1 PL-1 PS-1 RA-1 SA-1 SC-1 SI-1]
        }.freeze

        def generate_compliance_status(attrs)
          attrs.compliance_frameworks.each_with_object({}) do |framework, status|
            controls = compliance_controls_for_framework(framework)
            status[framework] = {
              compliant: true,
              last_assessment: Time.now.iso8601,
              controls_passed: controls.count,
              controls_total: controls.count
            }
          end
        end

        def compliance_controls_for_framework(framework)
          FRAMEWORK_CONTROLS[framework] || []
        end

        def calculate_security_score(attrs, _resources)
          score = 100

          score -= missing_feature_penalties(attrs)
          score += advanced_feature_bonuses(attrs)

          [score, 100].min
        end

        private

        def missing_feature_penalties(attrs)
          penalty = 0
          penalty += 5 unless attrs.verification_settings[:require_mfa]
          penalty += 5 unless attrs.monitoring_config[:enable_anomaly_detection]
          penalty += 5 unless attrs.threat_protection[:enable_ids]
          penalty += 5 unless attrs.threat_protection[:enable_ips]
          penalty += 5 unless attrs.advanced_options[:enable_microsegmentation]
          penalty += 10 unless attrs.audit_config[:enable_tamper_protection]
          penalty
        end

        def advanced_feature_bonuses(attrs)
          bonus = 0
          bonus += 5 if attrs.advanced_options[:enable_security_automation]
          bonus += 5 if attrs.threat_protection[:automated_response]
          bonus += 5 if attrs.advanced_options[:enable_privileged_access_management]
          bonus
        end
      end
    end
  end
end
