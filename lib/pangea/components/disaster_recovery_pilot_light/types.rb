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

require_relative 'types/region_configs'
require_relative 'types/data_configs'
require_relative 'types/operational_configs'
require_relative 'types/optimization_configs'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # Main component attributes
      class DisasterRecoveryPilotLightAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Core configuration
        attribute :dr_name, Types::String
        attribute :dr_description, Types::String.default("Pilot light disaster recovery infrastructure")

        # Region configuration
        attribute :primary_region, PrimaryRegionConfig
        attribute :dr_region, DRRegionConfig

        # Critical data
        attribute :critical_data, CriticalDataConfig.default { CriticalDataConfig.new({}) }

        # Pilot light configuration
        attribute :pilot_light, PilotLightConfig.default { PilotLightConfig.new({}) }

        # Activation configuration
        attribute :activation, ActivationConfig.default { ActivationConfig.new({}) }

        # Testing configuration
        attribute :testing, TestingConfig.default { TestingConfig.new({}) }

        # Cost optimization
        attribute :cost_optimization, CostOptimizationConfig.default { CostOptimizationConfig.new({}) }

        # Monitoring
        attribute :monitoring, MonitoringConfig.default { MonitoringConfig.new({}) }

        # Compliance
        attribute :compliance, ComplianceConfig.default { ComplianceConfig.new({}) }

        # Advanced features
        attribute :enable_automated_failover, Types::Bool.default(false)
        attribute :enable_cross_region_vpc_peering, Types::Bool.default(true)
        attribute :enable_infrastructure_as_code_sync, Types::Bool.default(true)
        attribute :enable_application_config_sync, Types::Bool.default(true)

        # Resource tagging
        attribute :tags, Types::Hash.default({}.freeze)

        # Custom validations
        def validate!
          errors = []

          # Validate regions are different
          if primary_region.region == dr_region.region
            errors << "Primary and DR regions must be different"
          end

          # Validate CIDR blocks don't overlap
          if primary_region.vpc_cidr == dr_region.vpc_cidr && enable_cross_region_vpc_peering
            errors << "VPC CIDR blocks must not overlap when cross-region peering is enabled"
          end

          # Validate critical data configuration
          if critical_data.databases.empty? && critical_data.s3_buckets.empty? && critical_data.efs_filesystems.empty?
            errors << "At least one type of critical data must be specified"
          end

          # Validate backup retention
          if critical_data.backup_retention_days < 1 || critical_data.backup_retention_days > 35
            errors << "Backup retention must be between 1 and 35 days"
          end

          # Validate RTO/RPO
          if compliance.rto_hours < 1
            errors << "RTO must be at least 1 hour"
          end

          if compliance.rpo_hours < 0
            errors << "RPO cannot be negative"
          end

          if compliance.rpo_hours > compliance.rto_hours
            errors << "RPO should not exceed RTO"
          end

          # Validate activation configuration
          if activation.activation_method == 'automated' && !enable_automated_failover
            errors << "Automated activation requires enable_automated_failover to be true"
          end

          if activation.health_check_threshold < 1 || activation.health_check_threshold > 10
            errors << "Health check threshold must be between 1 and 10"
          end

          if activation.activation_timeout < 60 || activation.activation_timeout > 3600
            errors << "Activation timeout must be between 60 and 3600 seconds"
          end

          # Validate pilot light configuration
          if pilot_light.data_sync_interval < 60 || pilot_light.data_sync_interval > 86400
            errors << "Data sync interval must be between 60 and 86400 seconds"
          end

          if pilot_light.auto_scaling_min > pilot_light.auto_scaling_max
            errors << "Auto scaling min cannot exceed max"
          end

          # Validate monitoring configuration
          if monitoring.replication_lag_threshold_seconds < 1
            errors << "Replication lag threshold must be at least 1 second"
          end

          # Validate cost optimization
          if cost_optimization.reserved_capacity_percentage < 0 || cost_optimization.reserved_capacity_percentage > 100
            errors << "Reserved capacity percentage must be between 0 and 100"
          end

          # Validate testing configuration
          if testing.test_scenarios.empty? && testing.automated_testing
            errors << "Test scenarios must be specified when automated testing is enabled"
          end

          raise ArgumentError, errors.join(", ") unless errors.empty?

          true
        end
      end
    end
  end
end
