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
  module Architectures
    module Types
      # Auto scaling configuration
      # Note: min <= max constraint is validated in Types.validate_auto_scaling_config
      AutoScalingConfig = Hash.schema(
        min: Integer.constrained(gteq: 1),
        max: Integer.constrained(gteq: 1),
        desired: Integer.constrained(gteq: 1).optional
      )

      # High availability configuration
      HighAvailabilityConfig = Hash.schema(
        multi_az: Bool.default(true),
        backup_retention_days: Integer.constrained(gteq: 0, lteq: 35).default(7),
        automated_backup: Bool.default(true),
        cross_region_backup: Bool.default(false)
      )

      # Security configuration
      SecurityConfig = Hash.schema(
        encryption_at_rest: Bool.default(true),
        encryption_in_transit: Bool.default(true),
        enable_waf: Bool.default(false),
        enable_ddos_protection: Bool.default(false),
        compliance_standards: Array.of(String).default([].freeze)
      )

      # Monitoring configuration
      MonitoringConfig = Hash.schema(
        detailed_monitoring: Bool.default(true),
        enable_logging: Bool.default(true),
        log_retention_days: Integer.constrained(gteq: 1, lteq: 3653).default(30),
        enable_alerting: Bool.default(true),
        enable_tracing: Bool.default(false)
      )

      # Cost optimization configuration
      CostOptimizationConfig = Hash.schema(
        use_spot_instances: Bool.default(false),
        use_reserved_instances: Bool.default(false),
        enable_auto_shutdown: Bool.default(false),
        cost_budget_monthly: Float.optional
      )

      # Network configuration
      NetworkConfig = Hash.schema(
        vpc_cidr: String.constrained(format: /^\d+\.\d+\.\d+\.\d+\/\d+$/),
        availability_zones: Array.of(AvailabilityZone).constrained(min_size: 1, max_size: 6),
        enable_nat_gateway: Bool.default(true),
        enable_vpc_endpoints: Bool.default(false)
      )

      # Backup configuration
      BackupConfig = Hash.schema(
        backup_schedule: String.default('daily'),
        retention_days: Integer.constrained(gteq: 1, lteq: 2555).default(30),
        cross_region_backup: Bool.default(false),
        point_in_time_recovery: Bool.default(false)
      )

      # Disaster recovery configuration
      DisasterRecoveryConfig = Hash.schema(
        rto_hours: Float.constrained(gteq: 0.0, lteq: 72.0),
        rpo_hours: Float.constrained(gteq: 0.0, lteq: 24.0),
        dr_region: Region,
        automated_failover: Bool.default(false),
        testing_schedule: String.default('monthly')
      )

      # Performance configuration
      PerformanceConfig = Hash.schema(
        enable_caching: Bool.default(false),
        cache_engine: String.default('redis').enum('redis', 'memcached'),
        enable_cdn: Bool.default(false),
        connection_pooling: Bool.default(true)
      )

      # Scaling configuration
      ScalingConfig = Hash.schema(
        auto_scaling: AutoScalingConfig,
        scale_out_cooldown: Integer.constrained(gteq: 60, lteq: 3600).default(300),
        scale_in_cooldown: Integer.constrained(gteq: 60, lteq: 3600).default(300),
        target_cpu_utilization: Float.constrained(gteq: 10.0, lteq: 90.0).default(70.0)
      )

      # Base architecture attributes that all architectures inherit
      BaseArchitectureAttributes = Hash.schema(
        name: String,
        environment: Environment,
        region: Region,
        tags: Tags.default({}.freeze)
      )
    end
  end
end
