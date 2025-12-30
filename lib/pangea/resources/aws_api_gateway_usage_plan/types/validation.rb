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
        # Validation methods for API Gateway Usage Plan attributes
        module ApiGatewayUsagePlanValidation
          def self.validate_name(name)
            unless name.match?(/\A[a-zA-Z0-9\-_\s]{1,255}\z/)
              raise Dry::Struct::Error, "Usage plan name must be 1-255 characters"
            end
          end

          def self.validate_api_stages(api_stages)
            api_stages.each do |stage|
              unless stage[:api_id].match?(/\A[a-z0-9]{10}\z/)
                raise Dry::Struct::Error, "Invalid API ID format: #{stage[:api_id]}"
              end

              unless stage[:stage].match?(/\A[a-zA-Z0-9\-_]{1,128}\z/)
                raise Dry::Struct::Error, "Invalid stage name: #{stage[:stage]}"
              end
            end
          end

          def self.validate_throttle_settings(throttle_settings)
            return unless throttle_settings

            if throttle_settings[:burst_limit] && throttle_settings[:burst_limit] <= 0
              raise Dry::Struct::Error, "Burst limit must be positive"
            end

            if throttle_settings[:rate_limit] && throttle_settings[:rate_limit] <= 0
              raise Dry::Struct::Error, "Rate limit must be positive"
            end
          end

          def self.validate_quota_settings(quota_settings)
            return unless quota_settings

            if quota_settings[:limit] <= 0
              raise Dry::Struct::Error, "Quota limit must be positive"
            end

            if quota_settings[:offset] && quota_settings[:offset] < 0
              raise Dry::Struct::Error, "Quota offset cannot be negative"
            end
          end

          def self.generate_default_description(attrs)
            plan_type = attrs.quota_settings ? "Quota-based" : "Throttle-only"
            "#{plan_type} usage plan for #{attrs.name}"
          end

          def self.validate_all(attrs)
            validate_name(attrs.name)
            validate_api_stages(attrs.api_stages)
            validate_throttle_settings(attrs.throttle_settings)
            validate_quota_settings(attrs.quota_settings)
          end
        end
      end
    end
  end
end
