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
        # SSM Automation runbook generation
        module Runbook
          def generate_activation_runbook(attrs)
            <<~YAML
              schemaVersion: "0.3"
              description: "DR Activation Runbook for #{attrs.dr_name}"
              parameters:
                ActivationType:
                  type: String
                  description: Type of activation (test or real)
                  default: test
              mainSteps:
                - name: ValidatePrimaryHealth
                  action: "aws:executeScript"
                  inputs:
                    Runtime: python3.8
                    Handler: validate_primary
                    Script: |
                      def validate_primary(events, context):
                          # Check primary region health
                          return {"status": "unhealthy"}

                - name: ActivateDRResources
                  action: "aws:executeStateMachine"
                  inputs:
                    stateMachineArn: "ACTIVATION_STATE_MACHINE_ARN"
                    input: |
                      {
                        "activation_type": "{{ ActivationType }}",
                        "timestamp": "{{ global:DATE_TIME }}"
                      }

                - name: ValidateDRActivation
                  action: "aws:waitForAwsResourceProperty"
                  inputs:
                    Service: autoscaling
                    Api: DescribeAutoScalingGroups
                    AutoScalingGroupNames:
                      - "DR_ASG_NAME"
                    PropertySelector: "$.AutoScalingGroups[0].DesiredCapacity"
                    DesiredValues:
                      - "{{ MinInstances }}"

                - name: UpdateDNS
                  action: "aws:executeScript"
                  onFailure: Continue
                  inputs:
                    Runtime: python3.8
                    Handler: update_dns
                    Script: |
                      def update_dns(events, context):
                          if events['ActivationType'] == 'real':
                              # Update Route 53 records
                              pass
                          return {"status": "success"}
              outputs:
                - ActivationTime:
                    Value: "{{ global:DATE_TIME }}"
                - ActivationStatus:
                    Value: "Completed"
            YAML
          end
        end
      end
    end
  end
end
