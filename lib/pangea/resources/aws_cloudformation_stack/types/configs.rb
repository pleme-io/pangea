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
        # Common CloudFormation Stack configurations
        module CloudFormationStackConfigs
          # Simple stack with inline template
          def self.simple_stack(name, template_body)
            {
              name: name,
              template_body: template_body,
              on_failure: 'ROLLBACK'
            }
          end

          # Stack from S3 template URL
          def self.s3_template_stack(name, template_url, parameters: {})
            {
              name: name,
              template_url: template_url,
              parameters: parameters,
              on_failure: 'ROLLBACK'
            }
          end

          # IAM-enabled stack
          def self.iam_stack(name, template_body, iam_role_arn: nil)
            {
              name: name,
              template_body: template_body,
              capabilities: %w[CAPABILITY_IAM CAPABILITY_NAMED_IAM],
              iam_role_arn: iam_role_arn,
              enable_termination_protection: true
            }
          end

          # Stack with notification
          def self.monitored_stack(name, template_body, notification_arns)
            {
              name: name,
              template_body: template_body,
              notification_arns: notification_arns,
              on_failure: 'ROLLBACK',
              timeout_in_minutes: 30
            }
          end

          # Production stack with full protection
          def self.production_stack(name, template_url, parameters: {})
            {
              name: name,
              template_url: template_url,
              parameters: parameters,
              capabilities: %w[CAPABILITY_IAM CAPABILITY_NAMED_IAM],
              enable_termination_protection: true,
              disable_rollback: false,
              timeout_in_minutes: 60
            }
          end

          # Stack with policy protection
          def self.protected_stack(name, template_body, policy_body)
            {
              name: name,
              template_body: template_body,
              policy_body: policy_body,
              capabilities: ['CAPABILITY_IAM'],
              enable_termination_protection: true
            }
          end
        end
      end
    end
  end
end
