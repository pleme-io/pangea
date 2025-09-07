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
require 'pangea/resources/aws_ecr_repository_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECR Repository Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECR Repository Policy attributes
      # @option attributes [String] :repository The name of the repository
      # @option attributes [String] :policy The policy document as JSON string
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Cross-account access policy
      #   cross_account_policy = aws_ecr_repository_policy(:cross_account, {
      #     repository: ecr_repo.name,
      #     policy: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [
      #         {
      #           Effect: "Allow",
      #           Principal: {
      #             AWS: "arn:aws:iam::123456789012:root"
      #           },
      #           Action: [
      #             "ecr:GetDownloadUrlForLayer",
      #             "ecr:BatchGetImage",
      #             "ecr:BatchCheckLayerAvailability"
      #           ]
      #         }
      #       ]
      #     })
      #   })
      #
      # @example Service-specific access policy
      #   service_policy = aws_ecr_repository_policy(:service_access, {
      #     repository: ecr_repo.name,
      #     policy: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [
      #         {
      #           Effect: "Allow",
      #           Principal: {
      #             Service: "ecs-tasks.amazonaws.com"
      #           },
      #           Action: [
      #             "ecr:GetDownloadUrlForLayer",
      #             "ecr:BatchGetImage",
      #             "ecr:BatchCheckLayerAvailability"
      #           ]
      #         }
      #       ]
      #     })
      #   })
      #
      # @example Using data source for policy
      #   policy_doc = data(:aws_iam_policy_document, :ecr_policy) do
      #     statement do
      #       effect "Allow"
      #       principal do
      #         aws account_arns
      #       end
      #       action [
      #         "ecr:GetDownloadUrlForLayer",
      #         "ecr:BatchGetImage",
      #         "ecr:BatchCheckLayerAvailability"
      #       ]
      #     end
      #   end
      #   
      #   repo_policy = aws_ecr_repository_policy(:data_policy, {
      #     repository: ecr_repo.name,
      #     policy: policy_doc.json
      #   })
      def aws_ecr_repository_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::Types::ECRRepositoryPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecr_repository_policy, name) do
          # Repository reference
          repository policy_attrs.repository
          
          # Policy document
          policy policy_attrs.policy
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ecr_repository_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            repository: "${aws_ecr_repository_policy.#{name}.repository}",
            policy: "${aws_ecr_repository_policy.#{name}.policy}",
            registry_id: "${aws_ecr_repository_policy.#{name}.registry_id}"
          },
          computed_properties: {
            statement_count: policy_attrs.statement_count,
            allows_cross_account_access: policy_attrs.allows_cross_account_access?,
            allowed_actions: policy_attrs.allowed_actions,
            denied_actions: policy_attrs.denied_actions,
            grants_pull_access: policy_attrs.grants_pull_access?,
            grants_push_access: policy_attrs.grants_push_access?,
            is_terraform_reference: policy_attrs.is_terraform_reference?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)