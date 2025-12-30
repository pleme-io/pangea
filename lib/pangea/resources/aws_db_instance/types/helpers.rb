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
        # Helper methods for AWS RDS Database Instance attributes
        module DbInstanceHelpers
          # Helper method to get engine family
          def engine_family
            case engine
            when /mysql/, /aurora-mysql/
              "mysql"
            when /postgres/, /aurora-postgresql/
              "postgresql"
            when /mariadb/
              "mariadb"
            when /oracle/
              "oracle"
            when /sqlserver/
              "sqlserver"
            else
              engine
            end
          end

          # Check if this is an Aurora engine
          def is_aurora?
            engine.start_with?("aurora")
          end

          # Check if this is a serverless instance
          def is_serverless?
            instance_class.include?("serverless")
          end

          # Check if subnet group is required
          def requires_subnet_group?
            !publicly_accessible || vpc_security_group_ids.any?
          end

          # Check if encryption is supported
          def supports_encryption?
            # All modern RDS engines support encryption
            true
          end

          # Estimate monthly cost (very rough estimate)
          def estimated_monthly_cost
            # Base hourly rates (simplified)
            hourly_rate = case instance_class
                          when /t3.micro/ then 0.017
                          when /t3.small/ then 0.034
                          when /t3.medium/ then 0.068
                          when /t3.large/ then 0.136
                          when /m5.large/ then 0.171
                          when /m5.xlarge/ then 0.342
                          when /r5.large/ then 0.250
                          when /r5.xlarge/ then 0.500
                          else 0.100 # Default estimate
                          end

            # Storage cost estimate ($0.10 per GB-month for gp3)
            storage_cost = allocated_storage ? allocated_storage * 0.10 : 0

            # Multi-AZ doubles the cost
            hourly_rate *= 2 if multi_az

            # Monthly cost (730 hours)
            compute_cost = hourly_rate * 730
            total_cost = compute_cost + storage_cost

            "~$#{total_cost.round(2)}/month"
          end
        end
      end
    end
  end
end
