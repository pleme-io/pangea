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
        class CloudFormationStackAttributes
          # Instance helper methods for CloudFormation stack attributes
          module InstanceMethods
            def uses_template_body?
              !template_body.nil?
            end

            def uses_template_url?
              !template_url.nil?
            end

            def has_parameters?
              parameters.any?
            end

            def has_capabilities?
              capabilities.any?
            end

            def has_notifications?
              notification_arns.any?
            end

            def has_policy?
              !policy_body.nil? || !policy_url.nil?
            end

            def has_timeout?
              !timeout_in_minutes.nil?
            end

            def has_iam_role?
              !iam_role_arn.nil?
            end

            def rollback_disabled?
              disable_rollback
            end

            def termination_protected?
              enable_termination_protection
            end

            def requires_iam_capabilities?
              capabilities.any? { |cap| cap.include?('IAM') }
            end

            def template_source
              return :body if template_body
              return :url if template_url

              :none
            end
          end
        end
      end
    end
  end
end
