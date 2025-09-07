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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudwatch_log_destination_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudWatch Log Destination Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudWatch Log Destination Policy attributes
      # @option attributes [String] :destination_name The name of the destination
      # @option attributes [String] :access_policy JSON policy document for access control
      # @option attributes [Boolean] :force_update Force policy update even if it exists
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Allow specific account access
      #   policy = aws_cloudwatch_log_destination_policy(:account_access, {
      #     destination_name: destination.name,
      #     access_policy: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [{
      #         Effect: "Allow",
      #         Principal: { AWS: "arn:aws:iam::123456789012:root" },
      #         Action: "logs:PutSubscriptionFilter",
      #         Resource: destination.arn
      #       }]
      #     })
      #   })
      #
      # @example Allow organization-wide access
      #   policy = aws_cloudwatch_log_destination_policy(:org_access, {
      #     destination_name: "organization-log-destination",
      #     access_policy: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [{
      #         Effect: "Allow",
      #         Principal: "*",
      #         Action: "logs:PutSubscriptionFilter",
      #         Resource: destination.arn,
      #         Condition: {
      #           StringEquals: {
      #             "aws:PrincipalOrgID": organization.id
      #           }
      #         }
      #       }]
      #     })
      #   })
      #
      # @example Multi-account access with conditions
      #   policy = aws_cloudwatch_log_destination_policy(:multi_account, {
      #     destination_name: log_destination.name,
      #     access_policy: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [
      #         {
      #           Sid: "AllowProductionAccounts",
      #           Effect: "Allow",
      #           Principal: { 
      #             AWS: [
      #               "arn:aws:iam::111111111111:root",
      #               "arn:aws:iam::222222222222:root"
      #             ]
      #           },
      #           Action: "logs:PutSubscriptionFilter",
      #           Resource: destination.arn
      #         },
      #         {
      #           Sid: "DenyTestAccounts",
      #           Effect: "Deny",
      #           Principal: { AWS: "arn:aws:iam::999999999999:root" },
      #           Action: "logs:PutSubscriptionFilter",
      #           Resource: destination.arn
      #         }
      #       ]
      #     }),
      #     force_update: true
      #   })
      def aws_cloudwatch_log_destination_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::Types::CloudWatchLogDestinationPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudwatch_logs_destination_policy, name) do
          destination_name policy_attrs.destination_name
          access_policy policy_attrs.access_policy
          force_update policy_attrs.force_update if policy_attrs.force_update
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudwatch_logs_destination_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            id: "${aws_cloudwatch_logs_destination_policy.#{name}.id}",
            destination_name: "${aws_cloudwatch_logs_destination_policy.#{name}.destination_name}",
            access_policy: "${aws_cloudwatch_logs_destination_policy.#{name}.access_policy}"
          },
          computed_properties: {
            policy_statements: policy_attrs.policy_statements,
            allowed_principals: policy_attrs.allowed_principals,
            denied_principals: policy_attrs.denied_principals,
            allows_organization: policy_attrs.allows_organization?,
            allows_all_accounts: policy_attrs.allows_all_accounts?,
            allowed_account_ids: policy_attrs.allowed_account_ids
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)