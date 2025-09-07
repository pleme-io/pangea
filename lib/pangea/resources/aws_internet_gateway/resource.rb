# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_internet_gateway/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # AWS Internet Gateway resource module that self-registers
    module AwsInternetGateway
      # Create an AWS Internet Gateway with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Internet Gateway attributes
      # @option attributes [String, nil] :vpc_id The VPC ID to attach to (optional)
      # @option attributes [Hash] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs and computed properties
      #
      # @example Create an Internet Gateway without immediate VPC attachment
      #   igw = aws_internet_gateway(:main_igw, {
      #     tags: { Name: "main-igw", Environment: "production" }
      #   })
      #
      # @example Create an Internet Gateway with VPC attachment
      #   igw = aws_internet_gateway(:main_igw, {
      #     vpc_id: vpc.id,
      #     tags: { Name: "main-igw" }
      #   })
      def aws_internet_gateway(name, attributes = {})
        # Validate attributes using dry-struct
        igw_attrs = AWS::Types::InternetGatewayAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_internet_gateway, name) do
          vpc_id igw_attrs.vpc_id if igw_attrs.vpc_id
          
          # Apply tags if present
          if igw_attrs.tags.any?
            tags do
              igw_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_internet_gateway',
          name: name,
          resource_attributes: igw_attrs.to_h,
          outputs: {
            id: "${aws_internet_gateway.#{name}.id}",
            arn: "${aws_internet_gateway.#{name}.arn}",
            owner_id: "${aws_internet_gateway.#{name}.owner_id}",
            vpc_id: "${aws_internet_gateway.#{name}.vpc_id}"
          }
        )
      end
    end
    
    # Maintain backward compatibility by extending AWS module
    module AWS
      include AwsInternetGateway
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AwsInternetGateway)