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
        # Common AWS managed policies for different use cases
        module AwsManagedPolicies
          # Administrative access
          ADMINISTRATOR_ACCESS = "arn:aws:iam::aws:policy/AdministratorAccess"
          POWER_USER_ACCESS = "arn:aws:iam::aws:policy/PowerUserAccess"
          IAM_FULL_ACCESS = "arn:aws:iam::aws:policy/IAMFullAccess"

          # Read-only access
          READ_ONLY_ACCESS = "arn:aws:iam::aws:policy/ReadOnlyAccess"
          SECURITY_AUDIT = "arn:aws:iam::aws:policy/SecurityAudit"

          # Service-specific policies
          module S3
            FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
            READ_ONLY = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
          end

          module EC2
            FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
            READ_ONLY = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
          end

          module RDS
            FULL_ACCESS = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
            READ_ONLY = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
          end

          module Lambda
            FULL_ACCESS = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
            READ_ONLY = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
            BASIC_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
            VPC_ACCESS_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
          end

          module CloudWatch
            FULL_ACCESS = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
            READ_ONLY = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
            AGENT_SERVER_POLICY = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
          end

          module ECS
            TASK_EXECUTION_ROLE = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
            SERVICE_ROLE = "arn:aws:iam::aws:policy/service-role/AmazonECSServiceRolePolicy"
          end

          # Helper methods for policy organization
          def self.all_policies
            constants.map { |const| const_get(const) }.select { |val| val.is_a?(String) }
          end

          def self.service_policies
            {
              s3: S3,
              ec2: EC2,
              rds: RDS,
              lambda: Lambda,
              cloudwatch: CloudWatch,
              ecs: ECS
            }
          end

          def self.administrative_policies
            [ADMINISTRATOR_ACCESS, POWER_USER_ACCESS, IAM_FULL_ACCESS]
          end

          def self.read_only_policies
            [READ_ONLY_ACCESS, SECURITY_AUDIT]
          end
        end
      end
    end
  end
end
