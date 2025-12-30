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

require_relative 'aws_managed_policies'

module Pangea
  module Resources
    module AWS
      module Types
        # Policy attachment patterns for common scenarios
        module AttachmentPatterns
          # Lambda execution role attachments
          def self.lambda_execution_role_policies
            [
              AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE
            ]
          end

          # Lambda VPC execution role attachments
          def self.lambda_vpc_execution_role_policies
            [
              AwsManagedPolicies::Lambda::BASIC_EXECUTION_ROLE,
              AwsManagedPolicies::Lambda::VPC_ACCESS_EXECUTION_ROLE
            ]
          end

          # EC2 instance role attachments for basic functionality
          def self.ec2_instance_basic_policies
            [
              AwsManagedPolicies::CloudWatch::AGENT_SERVER_POLICY
            ]
          end

          # ECS task execution role attachments
          def self.ecs_task_execution_policies
            [
              AwsManagedPolicies::ECS::TASK_EXECUTION_ROLE
            ]
          end

          # Development environment policies (more permissive)
          def self.development_policies
            [
              AwsManagedPolicies::S3::FULL_ACCESS,
              AwsManagedPolicies::CloudWatch::FULL_ACCESS,
              AwsManagedPolicies::Lambda::FULL_ACCESS
            ]
          end

          # Production environment policies (more restrictive)
          def self.production_read_only_policies
            [
              AwsManagedPolicies::S3::READ_ONLY,
              AwsManagedPolicies::CloudWatch::READ_ONLY,
              AwsManagedPolicies::EC2::READ_ONLY
            ]
          end
        end
      end
    end
  end
end
