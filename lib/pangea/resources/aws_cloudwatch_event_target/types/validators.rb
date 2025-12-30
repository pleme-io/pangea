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
        # Validation helpers for CloudWatch Event Target attributes
        module CloudWatchEventTargetValidators
          # Validate ARN format
          def self.validate_arn(arn)
            return unless arn
            return if arn.match?(/^arn:aws[a-z\-]*:/) || arn.match?(/^\$\{/)

            raise Dry::Struct::Error, 'arn must be a valid AWS ARN'
          end

          # Validate input options are mutually exclusive
          def self.validate_input_options(attrs)
            input_options = %i[input input_path input_transformer].count { |opt| attrs[opt] }
            return unless input_options > 1

            raise Dry::Struct::Error, 'Can only specify one of: input, input_path, or input_transformer'
          end

          # Validate role_arn format if provided
          def self.validate_role_arn(role_arn)
            return unless role_arn && !role_arn.empty?
            return if role_arn.match?(/^arn:aws[a-z\-]*:iam::\d{12}:role\//) ||
                      role_arn.match?(/^\$\{/)

            raise Dry::Struct::Error, 'role_arn must be a valid IAM role ARN'
          end

          # Validate ECS target configuration
          def self.validate_ecs_target(ecs_target)
            return unless ecs_target
            return if ecs_target[:task_definition_arn]

            raise Dry::Struct::Error, 'ecs_target requires task_definition_arn'
          end

          # Validate Batch target configuration
          def self.validate_batch_target(batch_target)
            return unless batch_target
            return if batch_target[:job_definition] && batch_target[:job_name]

            raise Dry::Struct::Error, 'batch_target requires job_definition and job_name'
          end
        end
      end
    end
  end
end
