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
  module Resources
    module AWS
      module Types
        class S3BucketObjectLockConfigurationAttributes
          # Helper instance methods for S3 bucket object lock configuration
          module InstanceMethods
            def has_default_retention?
              rule[:default_retention].present?
            end

            def governance_mode?
              rule.dig(:default_retention, :mode) == 'GOVERNANCE'
            end

            def compliance_mode?
              rule.dig(:default_retention, :mode) == 'COMPLIANCE'
            end

            def retention_period_in_days
              if rule.dig(:default_retention, :days)
                rule[:default_retention][:days]
              elsif rule.dig(:default_retention, :years)
                rule[:default_retention][:years] * 365
              else
                0
              end
            end

            def retention_period_in_years
              if rule.dig(:default_retention, :years)
                rule[:default_retention][:years]
              elsif rule.dig(:default_retention, :days)
                (rule[:default_retention][:days] / 365.0).round(2)
              else
                0.0
              end
            end

            def short_term_retention?
              retention_period_in_days <= 365
            end

            def medium_term_retention?
              days = retention_period_in_days
              days > 365 && days <= 2555
            end

            def long_term_retention?
              retention_period_in_days > 2555
            end

            def compliance_grade_retention?
              compliance_mode? && (retention_period_in_days >= 2555)
            end

            def allows_privileged_deletion?
              governance_mode?
            end

            def prevents_all_deletion?
              compliance_mode?
            end

            def estimated_storage_cost_impact
              days = retention_period_in_days

              base_impact = case days
                            when 0..365 then 'low'
                            when 366..2555 then 'medium'
                            else 'high'
                            end

              compliance_mode? ? "#{base_impact}_compliance" : base_impact
            end

            def retention_category
              case retention_period_in_days
              when 0..30 then 'monthly'
              when 31..365 then 'yearly'
              when 366..2555 then 'multi_year'
              else 'long_term_archive'
              end
            end

            def cross_account_scenario?
              expected_bucket_owner.present?
            end

            def bucket_name_only
              if bucket.start_with?('arn:')
                bucket.split(':').last
              else
                bucket
              end
            end

            def estimated_compliance_level
              if compliance_mode? && long_term_retention?
                'maximum'
              elsif compliance_mode? || (governance_mode? && medium_term_retention?)
                'high'
              elsif governance_mode? && short_term_retention?
                'standard'
              else
                'minimal'
              end
            end
          end
        end
      end
    end
  end
end
