# frozen_string_literal: true

require 'pangea/resources/base'
require_relative 'types'

module Pangea
  module Resources
    module AWS
      # AWS Step Functions Activity implementation
      # Provides type-safe function for creating activities
      def aws_sfn_activity(name, attributes = {})
        # Validate attributes using dry-struct
        validated_attrs = Types::Types::SfnActivityAttributes.new(attributes)
        
        # Create reference that will be returned
        ref = ResourceReference.new(
          type: 'aws_sfn_activity',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_sfn_activity.#{name}.id}",
            arn: "${aws_sfn_activity.#{name}.arn}",
            name: "${aws_sfn_activity.#{name}.name}",
            creation_date: "${aws_sfn_activity.#{name}.creation_date}",
            tags_all: "${aws_sfn_activity.#{name}.tags_all}"
          }
        )
        
        # Synthesize the Terraform resource
        resource :aws_sfn_activity, name do
          name validated_attrs.name
          
          # Tags
          if validated_attrs.tags
            tags validated_attrs.tags
          end
        end
        
        # Return the reference
        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)