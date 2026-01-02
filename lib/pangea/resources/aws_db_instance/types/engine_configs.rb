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
        # Common RDS engine configurations
        module RdsEngineConfigs
          # MySQL default configuration
          def self.mysql(version: "8.0")
            {
              engine: "mysql",
              engine_version: version,
              enabled_cloudwatch_logs_exports: ["error", "general", "slowquery"]
            }
          end

          # PostgreSQL default configuration
          def self.postgresql(version: "15")
            {
              engine: "postgres",
              engine_version: version,
              enabled_cloudwatch_logs_exports: ["postgresql"]
            }
          end

          # Aurora MySQL configuration
          def self.aurora_mysql(version: "8.0.mysql_aurora.3.02.0")
            {
              engine: "aurora-mysql",
              engine_version: version
            }
          end

          # Aurora PostgreSQL configuration
          def self.aurora_postgresql(version: "15.2")
            {
              engine: "aurora-postgresql",
              engine_version: version
            }
          end

          # MariaDB configuration
          def self.mariadb(version: "10.11")
            {
              engine: "mariadb",
              engine_version: version,
              enabled_cloudwatch_logs_exports: ["error", "general", "slowquery"]
            }
          end
        end
      end
    end
  end
end
