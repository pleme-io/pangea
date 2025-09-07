# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        # AWS CloudFormation Public Type Version resource
        # Publishes a version of a CloudFormation type to make it publicly available.
        module PublicTypeVersion
          def aws_cloudformation_public_type_version(name, attributes = {})
            resource(:aws_cloudformation_public_type_version, name) do
              arn attributes[:arn] if attributes[:arn]
              log_delivery_bucket attributes[:log_delivery_bucket] if attributes[:log_delivery_bucket]
              public_version_number attributes[:public_version_number] if attributes[:public_version_number]
              type attributes[:type] if attributes[:type]
              type_name attributes[:type_name] if attributes[:type_name]
            end
            
            ResourceReference.new(
              type: 'aws_cloudformation_public_type_version',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cloudformation_public_type_version.#{name}.id}",
                arn: "${aws_cloudformation_public_type_version.#{name}.arn}",
                public_type_arn: "${aws_cloudformation_public_type_version.#{name}.public_type_arn}"
              }
            )
          end
        end
      end
    end
  end
end