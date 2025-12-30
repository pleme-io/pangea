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
        # Helper methods for Lambda function attributes
        module LambdaHelpers
          def estimated_monthly_cost
            gb_seconds_cost = 0.0000166667
            request_cost = 0.20
            execution_time_seconds = 0.1
            monthly_requests = 1_000_000
            gb_seconds = (memory_size / 1024.0) * execution_time_seconds * monthly_requests
            (gb_seconds * gb_seconds_cost) + (monthly_requests / 1_000_000 * request_cost)
          end

          def requires_vpc?
            !vpc_config.nil?
          end

          def has_dlq?
            !dead_letter_config.nil?
          end

          def uses_efs?
            file_system_config.any?
          end

          def is_container_based?
            package_type == 'Image'
          end

          def supports_snap_start?
            runtime&.start_with?('java')
          end

          def architecture
            architectures.first
          end
        end
      end
    end
  end
end
