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
    module MultiRegionActiveActive
      # Validation module for MultiRegionActiveActiveAttributes
      module Validators
        def validate!
          errors = []
          errors.concat(validate_regions)
          errors.concat(validate_consistency)
          errors.concat(validate_failover)
          errors.concat(validate_database)
          errors.concat(validate_application)
          errors.concat(validate_traffic_routing)
          errors.concat(validate_compliance)
          raise ArgumentError, errors.join(', ') unless errors.empty?

          true
        end

        private

        def validate_regions
          errors = []
          region_names = regions.map(&:region)

          if region_names.uniq.length != region_names.length
            errors << 'Region names must be unique'
          end

          primary_regions = regions.select(&:is_primary)
          if primary_regions.empty?
            errors << 'At least one region must be marked as primary'
          elsif primary_regions.length > 1 && consistency.consistency_model == 'strong'
            errors << 'Strong consistency requires exactly one primary region'
          end

          cidr_blocks = regions.map(&:vpc_cidr)
          if cidr_blocks.uniq.length != cidr_blocks.length
            errors << 'VPC CIDR blocks must not overlap across regions'
          end

          errors
        end

        def validate_consistency
          errors = []

          if consistency.write_quorum_size > regions.length
            errors << 'Write quorum size cannot exceed number of regions'
          end

          if consistency.read_quorum_size > regions.length
            errors << 'Read quorum size cannot exceed number of regions'
          end

          errors
        end

        def validate_failover
          errors = []

          if failover.health_check_interval < 10 || failover.health_check_interval > 300
            errors << 'Health check interval must be between 10 and 300 seconds'
          end

          errors
        end

        def validate_database
          errors = []

          if global_database.engine == 'dynamodb' && global_database.instance_class
            errors << 'DynamoDB does not use instance classes'
          end

          if global_database.backup_retention_days < 1 || global_database.backup_retention_days > 35
            errors << 'Backup retention must be between 1 and 35 days'
          end

          errors
        end

        def validate_application
          errors = []
          return errors unless application

          if application.task_cpu < 256 || application.task_cpu > 16_384
            errors << 'Task CPU must be between 256 and 16384'
          end

          if application.task_memory < 512 || application.task_memory > 32_768
            errors << 'Task memory must be between 512 and 32768'
          end

          errors << 'Desired count must be at least 1' if application.desired_count < 1

          errors
        end

        def validate_traffic_routing
          errors = []

          if traffic_routing.cross_region_latency_threshold_ms < 1
            errors << 'Cross-region latency threshold must be at least 1ms'
          end

          errors
        end

        def validate_compliance
          errors = []
          region_names = regions.map(&:region)

          if compliance_regions.any? && !compliance_regions.all? { |r| region_names.include?(r) }
            errors << 'Compliance regions must be subset of configured regions'
          end

          errors
        end
      end
    end
  end
end
