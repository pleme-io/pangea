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
  module Components
    module DisasterRecoveryPilotLight
      module CodeGenerators
        # Step Functions workflow generation
        module Workflow
          def create_activation_workflow(attrs)
            {
              Comment: "DR Activation Workflow",
              StartAt: "PreActivationChecks",
              States: build_workflow_states(attrs)
            }
          end

          private

          def build_workflow_states(attrs)
            {
              PreActivationChecks: build_pre_activation_state(attrs),
              ActivateResources: build_activate_resources_state(attrs),
              PostActivationValidation: build_post_activation_state(attrs),
              NotifyCompletion: build_notify_completion_state
            }
          end

          def build_pre_activation_state(attrs)
            {
              Type: "Parallel",
              Branches: attrs.activation.pre_activation_checks.map do |check|
                {
                  StartAt: check[:name],
                  States: {
                    check[:name] => {
                      Type: "Task",
                      Resource: check[:function_arn] || "arn:aws:lambda:REGION:ACCOUNT:function:check",
                      End: true
                    }
                  }
                }
              end,
              Next: "ActivateResources"
            }
          end

          def build_activate_resources_state(attrs)
            {
              Type: "Parallel",
              Branches: [
                build_scale_compute_branch(attrs),
                build_promote_databases_branch
              ],
              Next: "PostActivationValidation"
            }
          end

          def build_scale_compute_branch(attrs)
            {
              StartAt: "ScaleCompute",
              States: {
                ScaleCompute: {
                  Type: "Task",
                  Resource: "arn:aws:states:::aws-sdk:autoscaling:updateAutoScalingGroup",
                  Parameters: {
                    AutoScalingGroupName: "DR_ASG_NAME",
                    MinSize: attrs.pilot_light.auto_scaling_min,
                    DesiredCapacity: attrs.pilot_light.auto_scaling_min
                  },
                  End: true
                }
              }
            }
          end

          def build_promote_databases_branch
            {
              StartAt: "PromoteDatabases",
              States: {
                PromoteDatabases: {
                  Type: "Task",
                  Resource: "arn:aws:states:::aws-sdk:rds:promoteReadReplicaDBCluster",
                  Parameters: { DBClusterIdentifier: "DR_CLUSTER_ID" },
                  End: true
                }
              }
            }
          end

          def build_post_activation_state(attrs)
            {
              Type: "Parallel",
              Branches: attrs.activation.post_activation_validation.map do |validation|
                {
                  StartAt: validation[:name],
                  States: {
                    validation[:name] => {
                      Type: "Task",
                      Resource: validation[:function_arn] || "arn:aws:lambda:REGION:ACCOUNT:function:validate",
                      End: true
                    }
                  }
                }
              end,
              Next: "NotifyCompletion"
            }
          end

          def build_notify_completion_state
            {
              Type: "Task",
              Resource: "arn:aws:states:::sns:publish",
              Parameters: {
                TopicArn: "DR_NOTIFICATION_TOPIC",
                Message: "DR activation completed successfully"
              },
              End: true
            }
          end
        end
      end
    end
  end
end
