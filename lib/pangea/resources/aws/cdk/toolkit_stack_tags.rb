# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CDK
        # AWS CDK Toolkit Stack Tags resource
        # Manages tags applied to CDK toolkit stacks.
        module ToolkitStackTags
          def aws_cdk_toolkit_stack_tags(name, attributes = {})
            resource(:aws_cdk_toolkit_stack_tags, name) do
              qualifier attributes[:qualifier] if attributes[:qualifier]
              if attributes[:tags]
                tags attributes[:tags]
              end
            end
            
            ResourceReference.new(
              type: 'aws_cdk_toolkit_stack_tags',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_toolkit_stack_tags.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end