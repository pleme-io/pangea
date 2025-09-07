# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS CloudWatch Log Data Protection Policy
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_data_protection_policy
      #
      # @example PII detection and redaction policy
      #   aws_cloudwatch_log_data_protection_policy(:pii_protection, {
      #     log_group_name: log_group.name,
      #     policy_document: jsonencode({
      #       "Name": "PIIDetectionPolicy",
      #       "Description": "Detect and redact PII data",
      #       "Version": "2021-06-01",
      #       "Statement": [
      #         {
      #           "Sid": "DetectPII",
      #           "DataIdentifier": [
      #             "arn:aws:dataprotection::aws:data-identifier/EmailAddress",
      #             "arn:aws:dataprotection::aws:data-identifier/CreditCardNumber"
      #           ],
      #           "Operation": {
      #             "Audit": {
      #               "FindingsDestination": {
      #                 "CloudWatchLogs": {
      #                   "LogGroup": audit_log_group.name
      #                 }
      #               }
      #             },
      #             "Deidentify": {
      #               "MaskConfig": {}
      #             }
      #           }
      #         }
      #       ]
      #     })
      #   })
      #
      # @example Custom data identifier protection
      #   aws_cloudwatch_log_data_protection_policy(:custom_protection, {
      #     log_group_name: "/aws/apigateway/access-logs",
      #     policy_document: protection_policy_ref.json
      #   })
      def aws_cloudwatch_log_data_protection_policy(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          log_group_name: {
            description: "Name of the log group to apply policy to",
            type: :string,
            required: true
          },
          policy_document: {
            description: "JSON policy document defining data protection rules",
            type: :string,
            required: true
          }
        })

        resource_block = resource(:aws_cloudwatch_log_data_protection_policy, name, transformed)
        
        Reference.new(
          type: :aws_cloudwatch_log_data_protection_policy,
          name: name,
          attributes: {
            id: "#{resource_block}.id",
            log_group_name: "#{resource_block}.log_group_name",
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