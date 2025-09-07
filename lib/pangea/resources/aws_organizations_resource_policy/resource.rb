# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS Organizations Resource Policy
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_resource_policy
      #
      # @example Allow trusted services to access organization
      #   aws_organizations_resource_policy(:trusted_services, {
      #     content: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [
      #         {
      #           Sid: "AllowTrustedServices",
      #           Effect: "Allow",
      #           Principal: {
      #             Service: [
      #               "config.amazonaws.com",
      #               "cloudtrail.amazonaws.com",
      #               "guardduty.amazonaws.com"
      #             ]
      #           },
      #           Action: [
      #             "organizations:DescribeOrganization",
      #             "organizations:ListAccounts",
      #             "organizations:ListAccountsForParent",
      #             "organizations:ListChildren",
      #             "organizations:DescribeAccount"
      #           ],
      #           Resource: "*"
      #         }
      #       ]
      #     }),
      #     tags: {
      #       Purpose: "trusted-service-access",
      #       ManagedBy: "platform-team"
      #     }
      #   })
      #
      # @example Cross-account backup access policy
      #   aws_organizations_resource_policy(:backup_access, {
      #     content: backup_policy_document_ref.json
      #   })
      def aws_organizations_resource_policy(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          content: {
            description: "JSON policy document content",
            type: :string,
            required: true
          },
          tags: {
            description: "Resource tags",
            type: :map
          }
        })

        resource_block = resource(:aws_organizations_resource_policy, name, transformed)
        
        Reference.new(
          type: :aws_organizations_resource_policy,
          name: name,
          attributes: {
            id: "#{resource_block}.id",
            arn: "#{resource_block}.arn",
            content: "#{resource_block}.content",
            tags_all: "#{resource_block}.tags_all"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)