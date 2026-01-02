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

require 'json'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # Activation automation infrastructure
      module Automation
        def create_activation_automation(name, attrs, dr_resources, tags)
          activation_resources = {}

          activation_resources[:role] = create_activation_role(name, tags)
          activation_resources[:policy] = create_activation_policy(
            name, activation_resources[:role]
          )

          activation_resources[:lambda] = create_activation_lambda(
            name, attrs, dr_resources, activation_resources[:role], tags
          )

          activation_resources[:state_machine] = create_activation_state_machine(
            name, attrs, activation_resources[:role], tags
          )

          activation_resources[:runbook] = create_activation_runbook(name, attrs, tags)

          if attrs.enable_automated_failover
            create_automated_failover_resources(
              name, attrs, activation_resources, tags
            )
          end

          activation_resources
        end

        private

        def create_activation_role(name, tags)
          aws_iam_role(
            component_resource_name(name, :activation_role),
            {
              name: "#{name}-dr-activation-role",
              assume_role_policy: JSON.generate({
                Version: "2012-10-17",
                Statement: [{
                  Effect: "Allow",
                  Principal: {
                    Service: ["lambda.amazonaws.com", "states.amazonaws.com"]
                  },
                  Action: "sts:AssumeRole"
                }]
              }),
              tags: tags
            }
          )
        end

        def create_activation_policy(name, role)
          aws_iam_role_policy_attachment(
            component_resource_name(name, :activation_policy),
            {
              role: role.name,
              policy_arn: "arn:aws:iam::aws:policy/PowerUserAccess"
            }
          )
        end

        def create_activation_lambda(name, attrs, dr_resources, role, tags)
          aws_lambda_function(
            component_resource_name(name, :activation_lambda),
            {
              function_name: "#{name}-dr-activation",
              role: role.arn,
              handler: "index.handler",
              runtime: "python3.9",
              timeout: attrs.activation.activation_timeout,
              memory_size: 512,
              environment: {
                variables: {
                  DR_ASG_NAME: dr_resources[:asg]&.name || "",
                  DR_REGION: attrs.dr_region.region,
                  MIN_INSTANCES: attrs.pilot_light.auto_scaling_min.to_s,
                  MAX_INSTANCES: attrs.pilot_light.auto_scaling_max.to_s,
                  ACTIVATION_METHOD: attrs.activation.activation_method
                }
              },
              code: { zip_file: generate_activation_lambda_code(attrs) },
              tags: tags
            }
          )
        end

        def create_activation_state_machine(name, attrs, role, tags)
          aws_sfn_state_machine(
            component_resource_name(name, :activation_state_machine),
            {
              name: "#{name}-dr-activation-workflow",
              role_arn: role.arn,
              definition: JSON.generate(create_activation_workflow(attrs)),
              logging_configuration: build_logging_config(name, attrs),
              tags: tags
            }
          )
        end

        def build_logging_config(name, attrs)
          {
            level: "ALL",
            include_execution_data: true,
            destinations: [{
              cloud_watch_logs_log_group: {
                log_group_arn: "arn:aws:logs:#{attrs.dr_region.region}:ACCOUNT:log-group:" \
                               "/aws/vendedlogs/states/#{name}-dr-activation:*"
              }
            }]
          }
        end

        def create_activation_runbook(name, attrs, tags)
          aws_ssm_document(
            component_resource_name(name, :activation_runbook),
            {
              name: "#{name}-DR-Activation-Runbook",
              document_type: "Automation",
              document_format: "YAML",
              content: generate_activation_runbook(attrs),
              tags: tags.merge(Type: "DR-Activation")
            }
          )
        end

        def create_automated_failover_resources(name, attrs, activation_resources, tags)
          event_rule_ref = aws_cloudwatch_event_rule(
            component_resource_name(name, :activation_trigger),
            {
              name: "#{name}-dr-activation-trigger",
              description: "Trigger DR activation on primary failure",
              event_pattern: JSON.generate({
                source: ["aws.health"],
                "detail-type": ["AWS Health Event"],
                detail: {
                  service: ["EC2", "RDS"],
                  eventTypeCategory: ["issue"]
                }
              }),
              tags: tags
            }
          )
          activation_resources[:trigger] = event_rule_ref

          activation_resources[:trigger_target] = aws_cloudwatch_event_target(
            component_resource_name(name, :activation_target),
            {
              rule: event_rule_ref.name,
              target_id: "1",
              arn: activation_resources[:lambda].arn
            }
          )
        end
      end
    end
  end
end
