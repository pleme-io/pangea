# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS CloudWatch Log Resource Policy
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy
      #
      # @example Basic log resource policy for cross-service access
      #   aws_cloudwatch_log_resource_policy(:api_gateway_policy, {
      #     policy_name: "ApiGatewayLogsResourcePolicy",
      #     policy_document: jsonencode({
      #       Version: "2012-10-17",
      #       Statement: [{
      #         Effect: "Allow",
      #         Principal: { Service: "apigateway.amazonaws.com" },
      #         Action: "logs:CreateLogStream",
      #         Resource: "arn:aws:logs:*:*:*"
      #       }]
      #     })
      #   })
      #
      # @example Route53 resolver query logging policy
      #   aws_cloudwatch_log_resource_policy(:route53_resolver, {
      #     policy_name: "Route53ResolverQueryLogging",
      #     policy_document: policy_doc_ref.json
      #   })
      def aws_cloudwatch_log_resource_policy(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          policy_name: {
            description: "Name of the resource policy",
            type: :string,
            required: true
          },
          policy_document: {
            description: "JSON policy document specifying permissions",
            type: :string,
            required: true
          }
        })

        resource_block = resource(:aws_cloudwatch_log_resource_policy, name, transformed)
        
        Reference.new(
          type: :aws_cloudwatch_log_resource_policy,
          name: name,
          attributes: {
            id: "#{resource_block}.id",
            policy_name: "#{resource_block}.policy_name",
            policy_document: "#{resource_block}.policy_document"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)