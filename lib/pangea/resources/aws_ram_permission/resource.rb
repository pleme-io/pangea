# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ram_permission/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Resource Access Manager (RAM) permission resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ram_permission(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::RamPermissionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ram_permission, name) do
          name attrs.name if attrs.name
          policy_template attrs.policy_template if attrs.policy_template
          resource_type attrs.resource_type if attrs.resource_type
          
          # Apply tags if present
          if attrs.tags.any?
            tags do
              attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ram_permission',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_ram_permission.#{name}.id}",
            arn: "${aws_ram_permission.#{name}.arn}",
            version: "${aws_ram_permission.#{name}.version}",
            type: "${aws_ram_permission.#{name}.type}",
            status: "${aws_ram_permission.#{name}.status}",
            creation_time: "${aws_ram_permission.#{name}.creation_time}",
            last_updated_time: "${aws_ram_permission.#{name}.last_updated_time}"
          },
          computed_properties: {
            # Computed properties from type definitions
          }
        )
      end
    end
  end
end


# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)