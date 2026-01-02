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
    module SiemSecurityPlatform
      # Shared helper methods for SIEM components
      module Helpers
        def aws_region
          'us-east-1'
        end

        def aws_account_id
          '123456789012'
        end

        def calculate_next_report_date(schedule)
          case schedule
          when 'daily'
            (Time.now + 86400).iso8601
          when 'weekly'
            (Time.now + 604800).iso8601
          when 'monthly'
            (Time.now + 2592000).iso8601
          end
        end

        def calculate_siem_security_score(attrs)
          score = 50

          # Encryption
          score += 10 if attrs.security_config[:enable_encryption_at_rest]
          score += 10 if attrs.security_config[:enable_encryption_in_transit]

          # Access control
          score += 10 if attrs.security_config[:enable_fine_grained_access]

          # Logging
          score += 5 if attrs.security_config[:enable_audit_logs]
          score += 5 if attrs.security_config[:enable_slow_logs]

          # Threat detection
          score += 5 if attrs.threat_detection[:enabled]
          score += 5 if attrs.threat_detection[:enable_ml_detection]

          score
        end

        def generate_siem_compliance_status(attrs)
          status = {
            frameworks: [],
            controls_met: 0,
            controls_total: 0,
            next_report: nil
          }

          attrs.compliance_config[:frameworks].each do |framework|
            framework_status = {
              name: framework,
              compliant: true,
              controls: []
            }
            status[:frameworks] << framework_status
          end

          status[:next_report] = calculate_next_report_date(
            attrs.compliance_config[:report_schedule]
          )

          status
        end
      end
    end
  end
end
