# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_media_store_container/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaStore Container with type-safe attributes
      def aws_media_store_container(name, attributes = {})
        container_attrs = Types::MediaStoreContainerAttributes.new(attributes)
        
        resource(:aws_media_store_container, name) do
          name container_attrs.name
          
          if container_attrs.tags.any?
            tags do
              container_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_media_store_container',
          name: name,
          resource_attributes: container_attrs.to_h,
          outputs: {
            arn: "${aws_media_store_container.#{name}.arn}",
            endpoint: "${aws_media_store_container.#{name}.endpoint}",
            name: "${aws_media_store_container.#{name}.name}"
          },
          computed: {
            name_valid: container_attrs.name_valid?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)