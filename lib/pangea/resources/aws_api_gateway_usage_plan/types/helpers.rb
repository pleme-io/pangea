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
        # Helper methods for API Gateway Usage Plan attributes
        module ApiGatewayUsagePlanHelpers
          def api_count
            api_stages.length
          end

          def has_throttling?
            !!throttle_settings
          end

          def has_quota?
            !!quota_settings
          end

          def quota_period
            quota_settings&.[](:period)&.downcase
          end

          def daily_quota?
            quota_period == 'day'
          end

          def monthly_quota?
            quota_period == 'month'
          end

          def estimated_monthly_cost
            base_cost = "$3.50 per million requests"
            quota_cost = has_quota? ? " + quota management" : ""
            "#{base_cost}#{quota_cost}"
          end

          def validate_configuration
            warnings = []

            if api_stages.empty?
              warnings << "Usage plan has no API stages - it won't apply to any APIs"
            end

            if !has_throttling? && !has_quota?
              warnings << "Usage plan has no throttling or quota - consider adding limits"
            end

            if throttle_settings && throttle_settings[:rate_limit] && throttle_settings[:rate_limit] < 1
              warnings << "Very low rate limit may cause service disruption"
            end

            if quota_settings && quota_settings[:limit] < 1000
              warnings << "Very low quota limit may impact user experience"
            end

            warnings
          end

          def strictness_level
            return "none" unless has_throttling? || has_quota?
            return "high" if has_throttling? && has_quota?
            return "medium" if has_quota?

            "low"
          end

          def production_ready?
            has_throttling? || has_quota?
          end

          def protection_level
            case strictness_level
            when "high"
              "comprehensive"
            when "medium"
              "quota_only"
            when "low"
              "throttle_only"
            else
              "unprotected"
            end
          end
        end
      end
    end
  end
end
