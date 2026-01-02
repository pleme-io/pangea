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
        # Helper methods and constants for API Gateway Stage
        module ApiGatewayStageHelpers
          # Cache cluster hourly costs by size
          CACHE_COSTS = {
            '0.5' => 0.02,
            '1.6' => 0.038,
            '6.1' => 0.2,
            '13.5' => 0.415,
            '28.4' => 0.83,
            '58.2' => 1.66,
            '118' => 3.32,
            '237' => 6.64
          }.freeze

          # Common access log formats
          LOG_FORMATS = {
            standard: '$context.requestId $context.requestTime $context.httpMethod ' \
                      '$context.path $context.status $context.responseLength',
            extended: '$context.requestId $context.extendedRequestId $context.requestTime ' \
                      '$context.httpMethod $context.path $context.status $context.responseLength ' \
                      '$context.error.message $context.error.messageString',
            json: '{"requestId":"$context.requestId","requestTime":"$context.requestTime",' \
                  '"httpMethod":"$context.httpMethod","path":"$context.path",' \
                  '"status":"$context.status","responseLength":"$context.responseLength",' \
                  '"sourceIp":"$context.identity.sourceIp","userAgent":"$context.identity.userAgent"}',
            auth_detailed: '$context.requestId $context.requestTime $context.httpMethod ' \
                           '$context.path $context.status $context.authorizer.principalId ' \
                           '$context.authorizer.claims.sub'
          }.freeze

          # Common method paths
          METHOD_PATHS = {
            all_methods: '/*/*',
            root_all: '/*',
            specific_all: '/users/*',
            specific_method: '/users/GET'
          }.freeze

          def self.common_log_formats
            LOG_FORMATS
          end

          def self.common_method_paths
            METHOD_PATHS
          end

          def self.cache_monthly_cost(cache_size)
            hourly_cost = CACHE_COSTS[cache_size] || 0
            hourly_cost * 24 * 30
          end
        end
      end
    end
  end
end
