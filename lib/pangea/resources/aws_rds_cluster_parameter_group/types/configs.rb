# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common RDS Cluster Parameter Group configurations
        module RdsClusterParameterGroupConfigs
          def self.aurora_mysql_performance(family: 'aurora-mysql8.0')
            {
              family: family,
              description: 'Aurora MySQL performance optimized parameter group',
              parameter: [
                { name: 'innodb_buffer_pool_size', value: '{DBInstanceClassMemory*3/4}', apply_method: 'pending-reboot' },
                { name: 'max_connections', value: 1000, apply_method: 'immediate' },
                { name: 'slow_query_log', value: 1, apply_method: 'immediate' },
                { name: 'long_query_time', value: 0.5, apply_method: 'immediate' },
                { name: 'innodb_lock_wait_timeout', value: 120, apply_method: 'immediate' },
                { name: 'wait_timeout', value: 28_800, apply_method: 'immediate' },
                { name: 'interactive_timeout', value: 28_800, apply_method: 'immediate' }
              ],
              tags: { Purpose: 'performance', Engine: 'aurora-mysql' }
            }
          end

          def self.aurora_postgresql_performance(family: 'aurora-postgresql14')
            {
              family: family,
              description: 'Aurora PostgreSQL performance optimized parameter group',
              parameter: [
                { name: 'shared_buffers', value: '{DBInstanceClassMemory/4}', apply_method: 'pending-reboot' },
                { name: 'max_connections', value: 1000, apply_method: 'pending-reboot' },
                { name: 'work_mem', value: '64MB', apply_method: 'immediate' },
                { name: 'maintenance_work_mem', value: '2GB', apply_method: 'immediate' },
                { name: 'effective_cache_size', value: '{DBInstanceClassMemory*3/4}', apply_method: 'immediate' },
                { name: 'random_page_cost', value: 1.1, apply_method: 'immediate' },
                { name: 'checkpoint_completion_target', value: 0.9, apply_method: 'immediate' }
              ],
              tags: { Purpose: 'performance', Engine: 'aurora-postgresql' }
            }
          end

          def self.development_logging(family:, engine_type:)
            parameters = if engine_type == 'mysql'
                           [
                             { name: 'slow_query_log', value: 1, apply_method: 'immediate' },
                             { name: 'long_query_time', value: 0.1, apply_method: 'immediate' },
                             { name: 'general_log', value: 1, apply_method: 'immediate' }
                           ]
                         else
                           [
                             { name: 'log_statement', value: 'all', apply_method: 'immediate' },
                             { name: 'log_min_duration_statement', value: 100, apply_method: 'immediate' },
                             { name: 'log_connections', value: 1, apply_method: 'immediate' },
                             { name: 'log_disconnections', value: 1, apply_method: 'immediate' }
                           ]
                         end

            { family: family, description: 'Development parameter group with extensive logging', parameter: parameters, tags: { Environment: 'development', Purpose: 'debugging' } }
          end

          def self.security_hardened(family:, engine_type:)
            parameters = if engine_type == 'mysql'
                           [
                             { name: 'sql_mode', value: 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION', apply_method: 'immediate' },
                             { name: 'innodb_lock_wait_timeout', value: 50, apply_method: 'immediate' }
                           ]
                         else
                           [
                             { name: 'statement_timeout', value: 300_000, apply_method: 'immediate' },
                             { name: 'idle_in_transaction_session_timeout', value: 600_000, apply_method: 'immediate' }
                           ]
                         end

            { family: family, description: 'Security hardened parameter group', parameter: parameters, tags: { Purpose: 'security', Compliance: 'hardened' } }
          end

          def self.high_connections(family:, engine_type:)
            parameters = if engine_type == 'mysql'
                           [
                             { name: 'max_connections', value: 5000, apply_method: 'immediate' },
                             { name: 'thread_cache_size', value: 256, apply_method: 'immediate' },
                             { name: 'table_open_cache', value: 4000, apply_method: 'immediate' },
                             { name: 'innodb_thread_concurrency', value: 0, apply_method: 'immediate' }
                           ]
                         else
                           [
                             { name: 'max_connections', value: 5000, apply_method: 'pending-reboot' },
                             { name: 'shared_buffers', value: '{DBInstanceClassMemory/3}', apply_method: 'pending-reboot' },
                             { name: 'work_mem', value: '32MB', apply_method: 'immediate' }
                           ]
                         end

            { family: family, description: 'High connection count optimization', parameter: parameters, tags: { Purpose: 'high-connections', Workload: 'connection-heavy' } }
          end
        end
      end
    end
  end
end
