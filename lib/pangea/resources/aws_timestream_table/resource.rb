# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_timestream_table/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Timestream table resource for storing time series data.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_timestream_table(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::TimestreamTableAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_timestream_table, name) do
          database_name attrs.database_name if attrs.database_name
          table_name attrs.table_name if attrs.table_name
          retention_properties attrs.retention_properties if attrs.retention_properties
          magnetic_store_write_properties attrs.magnetic_store_write_properties if attrs.magnetic_store_write_properties
          schema attrs.schema if attrs.schema
          
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
          type: 'aws_timestream_table',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_timestream_table.#{name}.id}",
            arn: "${aws_timestream_table.#{name}.arn}",
            status: "${aws_timestream_table.#{name}.status}"
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