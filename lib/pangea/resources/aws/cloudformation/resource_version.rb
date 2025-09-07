# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Resource Version resource
        # Registers a new version of a CloudFormation resource type.
        module ResourceVersion
          def aws_cloudformation_resource_version(name, attributes = {})
            resource(:aws_cloudformation_resource_version, name) do
              schema_handler_package attributes[:schema_handler_package] if attributes[:schema_handler_package]
              type_name attributes[:type_name] if attributes[:type_name]
              execution_role_arn attributes[:execution_role_arn] if attributes[:execution_role_arn]
              
              if attributes[:logging_config]
                logging_config do
                  log_group_name attributes[:logging_config][:log_group_name] if attributes[:logging_config][:log_group_name]
                  log_role_arn attributes[:logging_config][:log_role_arn] if attributes[:logging_config][:log_role_arn]
                end
              end
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_resource_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_resource_version.#{name}.id}",
                arn: "${aws_cloudformation_resource_version.#{name}.arn}",
                version_id: "${aws_cloudformation_resource_version.#{name}.version_id}"
              }
            )
          end
        end
      end
    end
  end
end