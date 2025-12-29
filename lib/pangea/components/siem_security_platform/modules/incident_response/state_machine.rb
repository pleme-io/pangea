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
    module SiemSecurityPlatform
      # Step Functions state machine for incident response
      module StateMachine
        def create_step_functions_state_machine(name, attrs, resources)
          state_machine_name = component_resource_name(name, :incident_response)
          resources[:step_functions][:incident_response] = aws_sfn_state_machine(state_machine_name, {
            name: "siem-incident-response-#{name}",
            role_arn: create_step_functions_role(name, "incident-response", attrs, resources),
            definition: JSON.pretty_generate(build_state_machine_definition(name, attrs, resources)),
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })
        end

        private

        def build_state_machine_definition(name, attrs, resources)
          {
            Comment: "SIEM Incident Response Workflow",
            StartAt: "ClassifyIncident",
            States: build_states(name, attrs, resources)
          }
        end

        def build_states(name, attrs, resources)
          {
            ClassifyIncident: classify_incident_state(name, attrs, resources),
            DetermineSeverity: determine_severity_state,
            CriticalResponse: critical_response_state(name, attrs, resources),
            HighResponse: severity_response_state(name, "high", attrs, resources),
            MediumResponse: severity_response_state(name, "medium", attrs, resources),
            LowResponse: severity_response_state(name, "low", attrs, resources),
            CreateIncidentTicket: create_ticket_state(name, attrs, resources)
          }
        end

        def classify_incident_state(name, attrs, resources)
          {
            Type: "Task",
            Resource: "arn:aws:states:::lambda:invoke",
            Parameters: {
              FunctionName: create_incident_classifier(name, attrs, resources),
              Payload: { "incident.$" => "$" }
            },
            Next: "DetermineSeverity"
          }
        end

        def determine_severity_state
          {
            Type: "Choice",
            Choices: [
              { Variable: "$.severity", StringEquals: "critical", Next: "CriticalResponse" },
              { Variable: "$.severity", StringEquals: "high", Next: "HighResponse" },
              { Variable: "$.severity", StringEquals: "medium", Next: "MediumResponse" }
            ],
            Default: "LowResponse"
          }
        end

        def critical_response_state(name, attrs, resources)
          {
            Type: "Parallel",
            Branches: [
              isolation_branch(name, attrs, resources),
              notification_branch(resources),
              forensics_branch(name, attrs, resources)
            ],
            Next: "CreateIncidentTicket"
          }
        end

        def isolation_branch(name, attrs, resources)
          {
            StartAt: "IsolateResource",
            States: {
              IsolateResource: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_isolation_lambda(name, attrs, resources),
                  Payload: { "action" => "isolate", "resource.$" => "$.affected_resource" }
                },
                End: true
              }
            }
          }
        end

        def notification_branch(resources)
          {
            StartAt: "NotifySOC",
            States: {
              NotifySOC: {
                Type: "Task",
                Resource: "arn:aws:states:::sns:publish",
                Parameters: {
                  TopicArn: resources[:sns_topics][:alerts]&.arn,
                  Message: { "incident.$" => "$", "priority" => "CRITICAL" }
                },
                End: true
              }
            }
          }
        end

        def forensics_branch(name, attrs, resources)
          {
            StartAt: "CollectForensics",
            States: {
              CollectForensics: {
                Type: "Task",
                Resource: "arn:aws:states:::lambda:invoke",
                Parameters: {
                  FunctionName: create_forensics_lambda(name, attrs, resources),
                  Payload: { "action" => "collect", "incident.$" => "$" }
                },
                End: true
              }
            }
          }
        end

        def severity_response_state(name, severity, attrs, resources)
          {
            Type: "Task",
            Resource: "arn:aws:states:::lambda:invoke",
            Parameters: {
              FunctionName: create_response_lambda(name, attrs, resources),
              Payload: { "severity" => severity, "incident.$" => "$" }
            },
            Next: "CreateIncidentTicket"
          }
        end

        def create_ticket_state(name, attrs, resources)
          {
            Type: "Task",
            Resource: "arn:aws:states:::lambda:invoke",
            Parameters: {
              FunctionName: create_ticketing_lambda(name, attrs, resources),
              Payload: { "action" => "create_ticket", "incident.$" => "$" }
            },
            End: true
          }
        end

        def create_step_functions_role(name, purpose, attrs, resources)
          role_name = component_resource_name(name, :sfn_role, purpose)
          role = aws_iam_role(role_name, {
            name: role_name.to_s,
            assume_role_policy: step_functions_assume_role_policy,
            tags: component_tags('siem_security_platform', name, attrs.tags)
          })

          aws_iam_role_policy(:"#{role_name}_policy", {
            role: role.id,
            policy: step_functions_policy(resources)
          })

          resources[:iam_roles][:"sfn_#{purpose}"] = role
          role.arn
        end

        def step_functions_assume_role_policy
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Action: "sts:AssumeRole",
              Effect: "Allow",
              Principal: { Service: "states.amazonaws.com" }
            }]
          })
        end

        def step_functions_policy(resources)
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [
              { Effect: "Allow", Action: ["lambda:InvokeFunction"], Resource: "arn:aws:lambda:*:*:function:siem-*" },
              { Effect: "Allow", Action: ["sns:Publish"], Resource: "arn:aws:sns:*:*:siem-*" }
            ]
          })
        end
      end
    end
  end
end
