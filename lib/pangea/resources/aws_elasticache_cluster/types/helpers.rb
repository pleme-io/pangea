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
        # Helper methods for ElastiCache cluster attributes
        module ElastiCacheHelpers
          def is_redis?
            engine == 'redis'
          end

          def is_memcached?
            engine == 'memcached'
          end

          def default_port
            is_redis? ? 6379 : 11_211
          end

          def supports_encryption?
            is_redis?
          end

          def supports_backup?
            is_redis?
          end

          def supports_auth?
            is_redis?
          end

          def engine_supports_encryption?
            return false unless is_redis?
            return true unless engine_version

            version_parts = engine_version.split('.').map(&:to_i)
            major = version_parts[0]
            minor = version_parts[1]
            patch = version_parts[2] || 0

            major > 3 || (major == 3 && minor > 2) || (major == 3 && minor == 2 && patch >= 6)
          end

          def is_cluster_mode?
            false
          end

          def estimated_monthly_cost
            hourly_rate = hourly_rate_for_node_type
            total_cost = hourly_rate * 730 * num_cache_nodes
            "~$#{total_cost.round(2)}/month"
          end

          private

          # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
          def hourly_rate_for_node_type
            case node_type
            when /t4g.nano/ then 0.016
            when /t4g.micro/ then 0.032
            when /t4g.small/ then 0.064
            when /t4g.medium/ then 0.128
            when /t3.micro/ then 0.017
            when /t3.small/ then 0.034
            when /t3.medium/ then 0.068
            when /m6g.large/ then 0.077
            when /m6g.xlarge/ then 0.154
            when /m5.large/ then 0.083
            when /m5.xlarge/ then 0.166
            when /r6g.large/ then 0.101
            when /r6g.xlarge/ then 0.202
            when /r5.large/ then 0.126
            when /r5.xlarge/ then 0.252
            else 0.100
            end
          end
          # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength
        end
      end
    end
  end
end
