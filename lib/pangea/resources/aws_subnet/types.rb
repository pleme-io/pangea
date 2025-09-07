# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Subnet resources
        #
        # @example
        #   SubnetAttributes.new({
        #     vpc_id: "${aws_vpc.main.id}",
        #     cidr_block: "10.0.1.0/24",
        #     availability_zone: "us-east-1a"
        #   })
        class SubnetAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Required attributes
        attribute :vpc_id, Resources::Types::String
        attribute :cidr_block, Resources::Types::CidrBlock
        attribute :availability_zone, Resources::Types::AwsAvailabilityZone
        
        # Optional attributes with defaults
        attribute :map_public_ip_on_launch, Resources::Types::Bool.default(false)
        attribute :tags, Resources::Types::AwsTags.default({})
        
        # Custom validation
        def self.new(attributes)
          # Validate CIDR block is a valid subnet size (typically /16 to /28)
          if attributes[:cidr_block] && !valid_subnet_cidr?(attributes[:cidr_block])
            raise Dry::Struct::Error, "Subnet CIDR block must be between /16 and /28"
          end
          
          super
        end
        
        private
        
        # Validate that CIDR block is appropriate for subnets
        def self.valid_subnet_cidr?(cidr)
          return false unless cidr.match?(/\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/)
          
          prefix_length = cidr.split('/').last.to_i
          prefix_length >= 16 && prefix_length <= 28
        end
      end
    end
  end
  end
end