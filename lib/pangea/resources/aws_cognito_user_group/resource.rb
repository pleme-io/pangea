# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cognito_user_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Cognito User Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Cognito user group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cognito_user_group(name, attributes = {})
        # Validate attributes using dry-struct
        group_attrs = Types::CognitoUserGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cognito_user_group, name) do
          name group_attrs.name
          user_pool_id group_attrs.user_pool_id
          description group_attrs.description if group_attrs.description
          precedence group_attrs.precedence if group_attrs.precedence
          role_arn group_attrs.role_arn if group_attrs.role_arn
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cognito_user_group',
          name: name,
          resource_attributes: group_attrs.to_h,
          outputs: {
            name: "${aws_cognito_user_group.#{name}.name}",
            role_arn: "${aws_cognito_user_group.#{name}.role_arn}"
          },
          computed_properties: {
            has_role: group_attrs.has_role?,
            has_precedence: group_attrs.has_precedence?,
            group_type: group_attrs.group_type
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)