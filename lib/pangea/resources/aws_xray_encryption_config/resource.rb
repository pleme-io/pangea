# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      # Type-safe resource function for AWS X-Ray Encryption Config
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes following AWS provider schema
      # @return [Pangea::Resources::Reference] Resource reference for chaining
      # 
      # @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/xray_encryption_config
      #
      # @example Enable X-Ray encryption with default key
      #   aws_xray_encryption_config(:default_encryption, {
      #     type: "NONE"
      #   })
      #
      # @example Enable X-Ray encryption with KMS key
      #   aws_xray_encryption_config(:kms_encryption, {
      #     type: "KMS",
      #     key_id: kms_key.arn
      #   })
      #
      # @example Regional X-Ray encryption configuration
      #   aws_xray_encryption_config(:regional_encryption, {
      #     type: "KMS",
      #     key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      #   })
      def aws_xray_encryption_config(name, attributes)
        transformed = Base.transform_attributes(attributes, {
          type: {
            description: "Type of encryption (NONE or KMS)",
            type: :string,
            required: true,
            enum: ["NONE", "KMS"]
          },
          key_id: {
            description: "KMS key ID or ARN (required when type is KMS)",
            type: :string
          }
        })

        resource_block = resource(:aws_xray_encryption_config, name, transformed)
        
        Reference.new(
          type: :aws_xray_encryption_config,
          name: name,
          attributes: {
            arn: "#{resource_block}.arn",
            id: "#{resource_block}.id",
            type: "#{resource_block}.type",
            key_id: "#{resource_block}.key_id"
          },
          resource: resource_block
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)