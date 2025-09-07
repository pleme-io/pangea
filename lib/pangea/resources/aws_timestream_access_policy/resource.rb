# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_timestream_access_policy/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides a Timestream access policy resource.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_timestream_access_policy(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::TimestreamAccessPolicyAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_timestream_access_policy, name) do
          database_name attrs.database_name if attrs.database_name
          table_name attrs.table_name if attrs.table_name
          policy_document attrs.policy_document if attrs.policy_document
          
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
          type: 'aws_timestream_access_policy',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_timestream_access_policy.#{name}.id}"
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