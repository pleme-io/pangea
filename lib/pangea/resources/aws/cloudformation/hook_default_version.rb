# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Hook Default Version resource
        # Sets the default version of a CloudFormation hook type.
        module HookDefaultVersion
          def aws_cloudformation_hook_default_version(name, attributes = {})
            resource(:aws_cloudformation_hook_default_version, name) do
              type_name attributes[:type_name] if attributes[:type_name]
              type_version_arn attributes[:type_version_arn] if attributes[:type_version_arn]
              version_id attributes[:version_id] if attributes[:version_id]
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_hook_default_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_hook_default_version.#{name}.id}",
                arn: "${aws_cloudformation_hook_default_version.#{name}.arn}"
              }
            )
          end
        end
      end
    end
  end
end