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
        # Common EventBridge Target configurations
        module EventBridgeTargetConfigs
          def self.lambda_target(rule:, target_id:, function_arn:, input: nil)
            { rule: rule, target_id: target_id, arn: function_arn, input: input }.compact
          end

          def self.sqs_target(rule:, target_id:, queue_arn:, message_group_id: nil)
            config = { rule: rule, target_id: target_id, arn: queue_arn }
            config[:sqs_parameters] = { message_group_id: message_group_id } if message_group_id
            config
          end

          def self.sns_target(rule:, target_id:, topic_arn:, role_arn: nil)
            { rule: rule, target_id: target_id, arn: topic_arn, role_arn: role_arn }.compact
          end

          def self.kinesis_target(rule:, target_id:, stream_arn:, role_arn:, partition_key_path: nil)
            config = { rule: rule, target_id: target_id, arn: stream_arn, role_arn: role_arn }
            config[:kinesis_parameters] = { partition_key_path: partition_key_path } if partition_key_path
            config
          end

          def self.ecs_target(rule:, target_id:, task_definition_arn:, role_arn:, cluster_arn: nil, launch_type: 'FARGATE', task_count: 1, subnets: [], security_groups: [])
            ecs_params = { task_definition_arn: task_definition_arn, task_count: task_count, launch_type: launch_type }
            if launch_type == 'FARGATE' && subnets.any?
              ecs_params[:network_configuration] = { awsvpc_configuration: { subnets: subnets, security_groups: security_groups, assign_public_ip: 'DISABLED' } }
            end
            { rule: rule, target_id: target_id, arn: cluster_arn || 'arn:aws:ecs', role_arn: role_arn, ecs_parameters: ecs_params }
          end

          def self.reliable_target(rule:, target_id:, arn:, role_arn: nil, max_retry_attempts: 3, max_event_age_hours: 24)
            { rule: rule, target_id: target_id, arn: arn, role_arn: role_arn,
              retry_policy: { maximum_retry_attempts: max_retry_attempts, maximum_event_age_in_seconds: max_event_age_hours * 3600 } }.compact
          end

          def self.target_with_dlq(rule:, target_id:, arn:, dlq_arn:, role_arn: nil)
            { rule: rule, target_id: target_id, arn: arn, role_arn: role_arn, dead_letter_config: { arn: dlq_arn } }.compact
          end

          def self.transformed_target(rule:, target_id:, arn:, input_template:, input_paths: nil, role_arn: nil)
            transformer = { input_template: input_template }
            transformer[:input_paths] = input_paths if input_paths
            { rule: rule, target_id: target_id, arn: arn, role_arn: role_arn, input_transformer: transformer }.compact
          end

          def self.batch_target(rule:, target_id:, job_queue_arn:, job_definition:, job_name:, role_arn:, array_size: nil)
            batch_params = { job_definition: job_definition, job_name: job_name }
            batch_params[:array_properties] = { size: array_size } if array_size
            { rule: rule, target_id: target_id, arn: job_queue_arn, role_arn: role_arn, batch_parameters: batch_params }
          end
        end
      end
    end
  end
end
