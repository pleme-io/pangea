# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_docdb_cluster_endpoint/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a DocumentDB cluster endpoint resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_docdb_cluster_endpoint(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::DocdbClusterEndpointAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_docdb_cluster_endpoint, name) do
          cluster_endpoint_identifier attrs.cluster_endpoint_identifier if attrs.cluster_endpoint_identifier
          cluster_identifier attrs.cluster_identifier if attrs.cluster_identifier
          endpoint_type attrs.endpoint_type if attrs.endpoint_type
          static_members attrs.static_members if attrs.static_members
          excluded_members attrs.excluded_members if attrs.excluded_members
          
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
          type: 'aws_docdb_cluster_endpoint',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_docdb_cluster_endpoint.#{name}.id}",
            arn: "${aws_docdb_cluster_endpoint.#{name}.arn}",
            endpoint: "${aws_docdb_cluster_endpoint.#{name}.endpoint}",
            cluster_identifier: "${aws_docdb_cluster_endpoint.#{name}.cluster_identifier}"
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