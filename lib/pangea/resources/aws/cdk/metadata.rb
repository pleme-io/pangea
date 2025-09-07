# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CDK
        # AWS CDK metadata resource
        module Umetadata
          def aws_cdk_metadata(name, attributes = {})
            resource(:aws_cdk_metadata, name) do
              attributes.each do |key, value|
                send(key, value) if value
              end
            end
            
            ResourceReference.new(
              type: 'aws_cdk_metadata',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_metadata.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end
