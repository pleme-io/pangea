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
    module SiemSecurityPlatform
      module StateMachine
        # Parallel workflow branches for critical incident response
        module Branches
          private

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
        end
      end
    end
  end
end
