# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_network_acl/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Provides an network ACL resource. You might set up network ACLs with rules similar to your security groups in order to add an additional layer of security to your VPC.
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_network_acl(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = Types::NetworkAclAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_network_acl, name) do
          vpc_id attrs.vpc_id if attrs.vpc_id
          subnet_ids attrs.subnet_ids if attrs.subnet_ids
          ingress attrs.ingress if attrs.ingress
          egress attrs.egress if attrs.egress
          tags attrs.tags if attrs.tags
          
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
          type: 'aws_network_acl',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_network_acl.#{name}.id}",
            arn: "${aws_network_acl.#{name}.arn}",
            owner_id: "${aws_network_acl.#{name}.owner_id}",
            vpc_id: "${aws_network_acl.#{name}.vpc_id}",
            subnet_ids: "${aws_network_acl.#{name}.subnet_ids}",
            ingress: "${aws_network_acl.#{name}.ingress}",
            egress: "${aws_network_acl.#{name}.egress}"
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