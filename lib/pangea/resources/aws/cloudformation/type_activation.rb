# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Type Activation resource
        # Activates a registered CloudFormation type in the calling account.
        # This makes the type available for use in CloudFormation templates.
        module TypeActivation
          # Creates an AWS CloudFormation Type Activation
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the type activation
          # @option attributes [String] :type_name The name of the type to activate (required)
          # @option attributes [String] :publisher_id The publisher ID if activating a third-party type
          # @option attributes [String] :type The type category (RESOURCE or HOOK)
          # @option attributes [String] :type_name_alias Alias for the type name
          # @option attributes [Boolean] :auto_update Whether to auto-update minor versions
          # @option attributes [String] :version_bump Type of version updates to auto-update
          # @option attributes [String] :major_version Major version to activate
          # @option attributes [Hash] :logging_config CloudWatch Logs configuration
          # @option attributes [String] :execution_role_arn IAM role for type execution
          #
          # @example Activate third-party resource type
          #   datadog_activation = aws_cloudformation_type_activation(:datadog_monitor, {
          #     type_name: "Datadog::Monitors::Monitor",
          #     publisher_id: "408988dff9e863704bcc72e7e13f8d645cee8311",
          #     type: "RESOURCE",
          #     auto_update: true,
          #     version_bump: "MINOR",
          #     type_name_alias: "DatadogMonitor",
          #     execution_role_arn: ref(:aws_iam_role, :datadog_execution, :arn),
          #     logging_config: {
          #       log_group_name: "DatadogCloudFormation",
          #       log_role_arn: ref(:aws_iam_role, :cf_logging, :arn)
          #     }
          #   })
          #
          # @return [ResourceReference] The type activation resource reference
          def aws_cloudformation_type_activation(name, attributes = {})
            resource(:aws_cloudformation_type_activation, name) do
              type_name attributes[:type_name] if attributes[:type_name]
              publisher_id attributes[:publisher_id] if attributes[:publisher_id]
              type attributes[:type] if attributes[:type]
              type_name_alias attributes[:type_name_alias] if attributes[:type_name_alias]
              auto_update attributes[:auto_update] if attributes.key?(:auto_update)
              version_bump attributes[:version_bump] if attributes[:version_bump]
              major_version attributes[:major_version] if attributes[:major_version]
              execution_role_arn attributes[:execution_role_arn] if attributes[:execution_role_arn]
              
              if attributes[:logging_config]
                logging_config do
                  log_group_name attributes[:logging_config][:log_group_name] if attributes[:logging_config][:log_group_name]
                  log_role_arn attributes[:logging_config][:log_role_arn] if attributes[:logging_config][:log_role_arn]
                end
              end
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_type_activation',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_type_activation.#{name}.id}",
                arn: "${aws_cloudformation_type_activation.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end