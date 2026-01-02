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

require 'pangea/resources/types'
require_relative 'types/aws_managed_policies'
require_relative 'types/attachment_patterns'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS IAM Role Policy Attachment resources
        class IamRolePolicyAttachmentAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Role name or ARN (required)
          attribute :role, Resources::Types::String

          # Policy ARN (required)
          attribute :policy_arn, Resources::Types::String

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)

            # Validate policy ARN format
            unless attrs.policy_arn.match?(/\Aarn:aws:iam::[0-9]{12}:policy\/.*\z/) ||
                   attrs.policy_arn.match?(/\Aarn:aws:iam::aws:policy\/.*\z/)
              raise Dry::Struct::Error, "policy_arn must be a valid IAM policy ARN"
            end

            # Validate role name/ARN format
            unless attrs.role.match?(/\A[a-zA-Z0-9+=,.@_-]+\z/) || # Role name format
                   attrs.role.match?(/\Aarn:aws:iam::[0-9]{12}:role\/.*\z/) # Role ARN format
              raise Dry::Struct::Error, "role must be a valid IAM role name or ARN"
            end

            attrs
          end

          # Check if policy is AWS managed
          def aws_managed_policy?
            policy_arn.include?("arn:aws:iam::aws:policy/")
          end

          # Check if policy is customer managed
          def customer_managed_policy?
            policy_arn.match?(/\Aarn:aws:iam::[0-9]{12}:policy\//)
          end

          # Extract policy name from ARN
          def policy_name
            policy_arn.split('/').last
          end

          # Extract account ID from policy ARN (for customer managed policies)
          def policy_account_id
            if customer_managed_policy?
              policy_arn.match(/arn:aws:iam::([0-9]{12}):policy\//)[1]
            end
          end

          # Check if role is specified by name or ARN
          def role_specified_by_arn?
            role.start_with?('arn:aws:iam::')
          end

          # Extract role name from ARN if provided as ARN
          def role_name
            if role_specified_by_arn?
              role.split('/').last
            else
              role
            end
          end

          # Generate a unique attachment identifier
          def attachment_id
            "#{role_name}-#{policy_name}"
          end

          # Check for potentially dangerous policy attachments
          def potentially_dangerous?
            dangerous_policies = [
              "AdministratorAccess",
              "PowerUserAccess",
              "IAMFullAccess",
              "AWSAccountManagementFullAccess",
              "SecurityAudit" # Can be risky if misused
            ]

            dangerous_policies.any? { |dangerous| policy_name.include?(dangerous) }
          end

          # Categorize policy type for better organization
          def policy_category
            case policy_name
            when /Admin/, /FullAccess/
              :administrative
            when /ReadOnly/, /ViewOnly/
              :read_only
            when /PowerUser/
              :power_user
            when /Service/
              :service_linked
            when /Lambda/, /EC2/, /S3/, /RDS/
              :service_specific
            else
              :custom
            end
          end

          # Security risk assessment
          def security_risk_level
            if potentially_dangerous?
              :high
            elsif policy_category == :administrative
              :high
            elsif policy_category == :power_user
              :medium
            elsif aws_managed_policy? && policy_category == :read_only
              :low
            elsif customer_managed_policy?
              :medium # Requires manual review
            else
              :low
            end
          end
        end
      end
    end
  end
end
