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
require 'pangea/resources/aws_ecr_lifecycle_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS ECR Lifecycle Policy with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] ECR Lifecycle Policy attributes
      # @option attributes [String] :repository The name of the repository
      # @option attributes [String] :policy The lifecycle policy document as JSON string
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Age-based cleanup policy
      #   age_cleanup = aws_ecr_lifecycle_policy(:age_cleanup, {
      #     repository: ecr_repo.name,
      #     policy: jsonencode({
      #       rules: [
      #         {
      #           rulePriority: 1,
      #           description: "Keep last 5 production images",
      #           selection: {
      #             tagStatus: "tagged",
      #             tagPrefixList: ["prod"],
      #             countType: "imageCountMoreThan",
      #             countNumber: 5
      #           },
      #           action: {
      #             type: "expire"
      #           }
      #         },
      #         {
      #           rulePriority: 2,
      #           description: "Delete images older than 30 days",
      #           selection: {
      #             tagStatus: "untagged",
      #             countType: "sinceImagePushed",
      #             countUnit: "days",
      #             countNumber: 30
      #           },
      #           action: {
      #             type: "expire"
      #           }
      #         }
      #       ]
      #     })
      #   })
      #
      # @example Count-based cleanup policy
      #   count_cleanup = aws_ecr_lifecycle_policy(:count_cleanup, {
      #     repository: ecr_repo.name,
      #     policy: jsonencode({
      #       rules: [
      #         {
      #           rulePriority: 1,
      #           description: "Keep only 10 images",
      #           selection: {
      #             tagStatus: "any",
      #             countType: "imageCountMoreThan",
      #             countNumber: 10
      #           },
      #           action: {
      #             type: "expire"
      #           }
      #         }
      #       ]
      #     })
      #   })
      #
      # @example Tagged image retention policy
      #   tagged_retention = aws_ecr_lifecycle_policy(:tagged_retention, {
      #     repository: ecr_repo.name,
      #     policy: jsonencode({
      #       rules: [
      #         {
      #           rulePriority: 1,
      #           description: "Keep latest 3 release images",
      #           selection: {
      #             tagStatus: "tagged",
      #             tagPrefixList: ["release"],
      #             countType: "imageCountMoreThan",
      #             countNumber: 3
      #           },
      #           action: {
      #             type: "expire"
      #           }
      #         },
      #         {
      #           rulePriority: 2,
      #           description: "Delete old development images",
      #           selection: {
      #             tagStatus: "tagged",
      #             tagPrefixList: ["dev", "feature"],
      #             countType: "sinceImagePushed",
      #             countUnit: "days",
      #             countNumber: 7
      #           },
      #           action: {
      #             type: "expire"
      #           }
      #         }
      #       ]
      #     })
      #   })
      def aws_ecr_lifecycle_policy(name, attributes = {})
        # Validate attributes using dry-struct
        policy_attrs = Types::Types::ECRLifecyclePolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ecr_lifecycle_policy, name) do
          # Repository reference
          repository policy_attrs.repository
          
          # Lifecycle policy document
          policy policy_attrs.policy
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ecr_lifecycle_policy',
          name: name,
          resource_attributes: policy_attrs.to_h,
          outputs: {
            repository: "${aws_ecr_lifecycle_policy.#{name}.repository}",
            policy: "${aws_ecr_lifecycle_policy.#{name}.policy}",
            registry_id: "${aws_ecr_lifecycle_policy.#{name}.registry_id}"
          },
          computed_properties: {
            rule_count: policy_attrs.rule_count,
            rule_priorities: policy_attrs.rule_priorities,
            has_tagged_image_rules: policy_attrs.has_tagged_image_rules?,
            has_untagged_image_rules: policy_attrs.has_untagged_image_rules?,
            has_count_based_rules: policy_attrs.has_count_based_rules?,
            has_age_based_rules: policy_attrs.has_age_based_rules?,
            estimated_retention_days: policy_attrs.estimated_retention_days,
            is_terraform_reference: policy_attrs.is_terraform_reference?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)