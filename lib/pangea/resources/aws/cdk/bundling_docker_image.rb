# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module CDK
        # AWS CDK bundling docker image resource
        module UbundlingUdockerUimage
          def aws_cdk_bundling_docker_image(name, attributes = {})
            resource(:aws_cdk_bundling_docker_image, name) do
              attributes.each do |key, value|
                send(key, value) if value
              end
            end
            
            ResourceReference.new(
              type: 'aws_cdk_bundling_docker_image',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_cdk_bundling_docker_image.#{name}.id}"
              }
            )
          end
        end
      end
    end
  end
end
