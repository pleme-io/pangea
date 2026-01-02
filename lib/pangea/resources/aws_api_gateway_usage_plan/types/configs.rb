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
        # Common API Gateway usage plan configurations
        module ApiGatewayUsagePlanConfigs
          # Basic usage plan with throttling only
          def self.basic_throttle_plan(plan_name, api_id, stage_name, rate_limit: 1000, burst_limit: 2000)
            {
              name: plan_name,
              description: "Basic throttling plan for #{stage_name}",
              api_stages: [{ api_id: api_id, stage: stage_name }],
              throttle_settings: { rate_limit: rate_limit, burst_limit: burst_limit }
            }
          end

          # Standard quota-based plan
          def self.quota_plan(plan_name, api_id, stage_name, daily_limit: 10000)
            {
              name: plan_name,
              description: "Quota-based usage plan for #{stage_name}",
              api_stages: [{ api_id: api_id, stage: stage_name }],
              quota_settings: { limit: daily_limit, period: 'DAY' }
            }
          end

          # Premium plan with both throttling and quota
          def self.premium_plan(plan_name, api_id, stage_name, monthly_quota: 1000000, rate_limit: 5000)
            {
              name: plan_name,
              description: "Premium usage plan with high limits",
              api_stages: [{ api_id: api_id, stage: stage_name }],
              throttle_settings: { rate_limit: rate_limit, burst_limit: rate_limit * 2 },
              quota_settings: { limit: monthly_quota, period: 'MONTH' }
            }
          end

          # Development plan with generous limits
          def self.development_plan(plan_name, api_id, stage_name)
            {
              name: plan_name,
              description: "Development usage plan with generous limits",
              api_stages: [{ api_id: api_id, stage: stage_name }],
              throttle_settings: { rate_limit: 10000, burst_limit: 20000 },
              quota_settings: { limit: 1000000, period: 'MONTH' },
              tags: { Environment: "development", Purpose: "API development and testing" }
            }
          end

          # Corporate enterprise plan
          def self.enterprise_plan(plan_name, api_id, stage_name, organization)
            {
              name: plan_name,
              description: "Enterprise usage plan for #{organization}",
              api_stages: [{ api_id: api_id, stage: stage_name }],
              throttle_settings: { rate_limit: 50000, burst_limit: 100000 },
              quota_settings: { limit: 10000000, period: 'MONTH' },
              tags: { Organization: organization, PlanType: "enterprise", SupportLevel: "premium" }
            }
          end
        end
      end
    end
  end
end
