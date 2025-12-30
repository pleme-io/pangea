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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # Cost optimization configuration
      class CostOptimizationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :use_spot_instances, Types::Bool.default(false)
        attribute :reserved_capacity_percentage, Types::Integer.default(0)
        attribute :auto_shutdown_non_critical, Types::Bool.default(true)
        attribute :data_lifecycle_policies, Types::Bool.default(true)
        attribute :compress_backups, Types::Bool.default(true)
        attribute :dedup_enabled, Types::Bool.default(true)
      end

      # Monitoring and alerting configuration
      class MonitoringConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :primary_region_monitoring, Types::Bool.default(true)
        attribute :dr_region_monitoring, Types::Bool.default(true)
        attribute :replication_lag_threshold_seconds, Types::Integer.default(300)
        attribute :backup_monitoring, Types::Bool.default(true)
        attribute :synthetic_monitoring, Types::Bool.default(true)
        attribute :dashboard_enabled, Types::Bool.default(true)
        attribute :alerting_enabled, Types::Bool.default(true)
      end

      # Compliance configuration
      class ComplianceConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :rto_hours, Types::Integer.default(4)
        attribute :rpo_hours, Types::Integer.default(1)
        attribute :data_residency_requirements, Types::Array.of(Types::String).default([].freeze)
        attribute :encryption_required, Types::Bool.default(true)
        attribute :audit_logging, Types::Bool.default(true)
        attribute :compliance_standards, Types::Array.of(Types::String).default([].freeze)
      end
    end
  end
end
