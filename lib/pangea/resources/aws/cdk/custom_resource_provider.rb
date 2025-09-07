# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CDK
        # AWS CDK custom resource provider resource
        module UcustomUresourceUprovider
          def aws_cdk_custom_resource_provider(name, attributes = {})
            resource(:aws_cdk_custom_resource_provider, name) do
              attributes.each do |key, value|
                send(key, value) if value
              end
            end
            
            ResourceReference.new(
              type: 'aws_cdk_custom_resource_provider',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_custom_resource_provider.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end
