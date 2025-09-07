# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_codedeploy_application/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeDeploy Application with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeDeploy application attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codedeploy_application(name, attributes = {})
        # Validate attributes using dry-struct
        app_attrs = Types::CodeDeployApplicationAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codedeploy_application, name) do
          # Set application name
          application_name app_attrs.application_name
          
          # Set compute platform
          compute_platform app_attrs.compute_platform
          
          # Apply tags
          if app_attrs.tags.any?
            tags do
              app_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codedeploy_application',
          name: name,
          resource_attributes: app_attrs.to_h,
          outputs: {
            id: "${aws_codedeploy_application.#{name}.id}",
            application_id: "${aws_codedeploy_application.#{name}.application_id}",
            application_name: "${aws_codedeploy_application.#{name}.application_name}",
            arn: "${aws_codedeploy_application.#{name}.arn}",
            linked_to_github: "${aws_codedeploy_application.#{name}.linked_to_github}",
            github_account_name: "${aws_codedeploy_application.#{name}.github_account_name}"
          },
          computed: {
            ec2_platform: app_attrs.ec2_platform?,
            lambda_platform: app_attrs.lambda_platform?,
            ecs_platform: app_attrs.ecs_platform?,
            supports_deployment_groups: app_attrs.supports_deployment_groups?,
            supports_blue_green: app_attrs.supports_blue_green?,
            supports_canary: app_attrs.supports_canary?,
            deployment_type_options: app_attrs.deployment_type_options
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)