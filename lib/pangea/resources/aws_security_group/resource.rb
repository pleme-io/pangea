# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_security_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Security Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Security Group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_security_group(name, attributes = {})
        # Validate attributes using dry-struct
        sg_attrs = AWS::Types::SecurityGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_security_group, name) do
          name_prefix sg_attrs.name_prefix if sg_attrs.name_prefix
          vpc_id sg_attrs.vpc_id if sg_attrs.vpc_id
          description sg_attrs.description if sg_attrs.description
          
          # Add ingress rules as array
          if sg_attrs.ingress_rules.any?
            ingress sg_attrs.ingress_rules
          end
          
          # Add egress rules as array
          if sg_attrs.egress_rules.any?
            egress sg_attrs.egress_rules
          end
          
          # Apply tags if present
          if sg_attrs.tags.any?
            tags do
              sg_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_security_group',
          name: name,
          resource_attributes: sg_attrs.to_h,
          outputs: {
            id: "${aws_security_group.#{name}.id}",
            arn: "${aws_security_group.#{name}.arn}",
            vpc_id: "${aws_security_group.#{name}.vpc_id}",
            owner_id: "${aws_security_group.#{name}.owner_id}",
            name: "${aws_security_group.#{name}.name}"
          }
        )
      end
    end
  end
end

# Note: Registration handled by main aws.rb module