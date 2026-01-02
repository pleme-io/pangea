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
        # Common parameter configurations for different engines
        module DbParameterConfigs
          # MySQL performance tuning parameters
          def self.mysql_performance(instance_class: "db.t3.micro")
            buffer_pool_size = case instance_class
                             when /t3.micro/ then "134217728"  # 128MB
                             when /t3.small/ then "268435456"  # 256MB
                             when /t3.medium/ then "536870912" # 512MB
                             when /m5.large/ then "1073741824" # 1GB
                             else "268435456" # Default 256MB
                             end

            [
              { name: "innodb_buffer_pool_size", value: buffer_pool_size, apply_method: "pending-reboot" },
              { name: "slow_query_log", value: "1", apply_method: "immediate" },
              { name: "long_query_time", value: "2", apply_method: "immediate" },
              { name: "max_connections", value: "100", apply_method: "immediate" }
            ]
          end

          # PostgreSQL performance tuning parameters
          def self.postgresql_performance(instance_class: "db.t3.micro")
            shared_buffers = case instance_class
                           when /t3.micro/ then "32MB"
                           when /t3.small/ then "64MB"
                           when /t3.medium/ then "128MB"
                           when /m5.large/ then "256MB"
                           else "64MB"
                           end

            [
              { name: "shared_buffers", value: shared_buffers, apply_method: "pending-reboot" },
              { name: "work_mem", value: "4MB", apply_method: "immediate" },
              { name: "maintenance_work_mem", value: "64MB", apply_method: "immediate" },
              { name: "checkpoint_completion_target", value: "0.9", apply_method: "immediate" },
              { name: "log_statement", value: "all", apply_method: "immediate" }
            ]
          end

          # Aurora MySQL parameters
          def self.aurora_mysql_performance
            [
              { name: "slow_query_log", value: "1", apply_method: "immediate" },
              { name: "long_query_time", value: "2", apply_method: "immediate" },
              { name: "binlog_format", value: "ROW", apply_method: "pending-reboot" },
              { name: "innodb_print_all_deadlocks", value: "1", apply_method: "immediate" }
            ]
          end

          # Aurora PostgreSQL parameters
          def self.aurora_postgresql_performance
            [
              { name: "shared_preload_libraries", value: "pg_stat_statements", apply_method: "pending-reboot" },
              { name: "log_statement", value: "all", apply_method: "immediate" },
              { name: "log_min_duration_statement", value: "1000", apply_method: "immediate" },
              { name: "checkpoint_completion_target", value: "0.9", apply_method: "immediate" }
            ]
          end
        end
      end
    end
  end
end
