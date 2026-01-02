# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        module AuroraClusterConfigs
          def self.mysql_development
            { engine: 'aurora-mysql', engine_mode: 'provisioned', backup_retention_period: 1, skip_final_snapshot: true,
              deletion_protection: false, enabled_cloudwatch_logs_exports: %w[slowquery], tags: { Environment: 'development', Engine: 'aurora-mysql' } }
          end

          def self.mysql_production
            { engine: 'aurora-mysql', engine_mode: 'provisioned', backup_retention_period: 14, skip_final_snapshot: false,
              deletion_protection: true, enabled_cloudwatch_logs_exports: %w[audit error general slowquery],
              performance_insights_enabled: true, monitoring_interval: 60, backtrack_window: 259_200, tags: { Environment: 'production', Engine: 'aurora-mysql' } }
          end

          def self.postgresql_development
            { engine: 'aurora-postgresql', engine_mode: 'provisioned', backup_retention_period: 1, skip_final_snapshot: true,
              deletion_protection: false, enabled_cloudwatch_logs_exports: %w[postgresql], tags: { Environment: 'development', Engine: 'aurora-postgresql' } }
          end

          def self.postgresql_production
            { engine: 'aurora-postgresql', engine_mode: 'provisioned', backup_retention_period: 14, skip_final_snapshot: false,
              deletion_protection: true, enabled_cloudwatch_logs_exports: %w[postgresql],
              performance_insights_enabled: true, monitoring_interval: 60, tags: { Environment: 'production', Engine: 'aurora-postgresql' } }
          end

          def self.serverless_v2(min_capacity: 0.5, max_capacity: 16.0)
            { engine: 'aurora-mysql', engine_mode: 'provisioned',
              serverless_v2_scaling_configuration: { min_capacity: min_capacity, max_capacity: max_capacity }, tags: { ServerlessVersion: 'v2' } }
          end

          def self.global_mysql
            { engine: 'aurora-mysql', engine_mode: 'global', backup_retention_period: 14, deletion_protection: true, tags: { ClusterType: 'global', Engine: 'aurora-mysql' } }
          end
        end
      end
    end
  end
end
