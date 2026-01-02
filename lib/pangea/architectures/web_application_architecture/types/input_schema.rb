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
    module WebApplicationArchitecture
      module Types
        # Web Application specific input configuration schema
        Input = Hash.schema(
          # Required attributes
          domain_name: DomainName,
          environment: Environment,

          # Network configuration
          region: Region.default('us-east-1'),
          vpc_cidr: String.constrained(format: /^\d+\.\d+\.\d+\.\d+\/\d+$/).default('10.0.0.0/16'),
          availability_zones: Array.of(AvailabilityZone).default(['us-east-1a', 'us-east-1b', 'us-east-1c']),

          # Compute configuration
          instance_type: InstanceType.default('t3.medium'),
          auto_scaling: AutoScalingConfig.default({ min: 1, max: 3, desired: 1 }),

          # Database configuration
          database_enabled: Bool.default(true),
          database_engine: DatabaseEngine.default('mysql'),
          database_instance_class: DatabaseInstanceClass.default('db.t3.micro'),
          database_allocated_storage: Integer.constrained(gteq: 20, lteq: 65536).default(20),

          # Load balancing and SSL
          ssl_certificate_arn: String.optional,
          allowed_cidr_blocks: Array.of(String).default(['0.0.0.0/0']),

          # High availability and scaling
          high_availability: Bool.default(true),

          # Performance features
          enable_caching: Bool.default(false),
          enable_cdn: Bool.default(false),

          # Monitoring and logging
          monitoring: MonitoringConfig.default({
            detailed_monitoring: true,
            enable_logging: true,
            log_retention_days: 30,
            enable_alerting: true,
            enable_tracing: false
          }),

          # Security settings
          security: SecurityConfig.default({
            encryption_at_rest: true,
            encryption_in_transit: true,
            enable_waf: false,
            enable_ddos_protection: false,
            compliance_standards: []
          }),

          # Backup configuration
          backup: BackupConfig.default({
            backup_schedule: 'daily',
            retention_days: 7,
            cross_region_backup: false,
            point_in_time_recovery: false
          }),

          # Cost optimization
          cost_optimization: CostOptimizationConfig.default({
            use_spot_instances: false,
            use_reserved_instances: false,
            enable_auto_shutdown: false
          }),

          # Tags
          tags: Tags.default({})
        )
      end
    end
  end
end
