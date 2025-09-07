# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module Pangea
  module Components
    module VpcWithSubnets
      module Types
        include Dry.Types()

        # CIDR block validation
        CidrBlock = Types::String.constrained(
          format: /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
        )

        # AWS availability zone format
        AvailabilityZone = Types::String.constrained(
          format: /\A[a-z]{2}-[a-z]+-\d+[a-z]\z/
        )

        # Component input attributes
        class VpcWithSubnetsAttributes < Dry::Struct
          # VPC configuration
          attribute :vpc_cidr, CidrBlock
          attribute :enable_dns_hostnames, Types::Bool.default(true)
          attribute :enable_dns_support, Types::Bool.default(true)
          
          # Subnet configuration
          attribute :availability_zones, Types::Array.of(AvailabilityZone)
          attribute :create_private_subnets, Types::Bool.default(true)
          attribute :create_public_subnets, Types::Bool.default(true)
          attribute :subnet_bits, Types::Integer.default(8).constrained(gteq: 1, lteq: 16)
          
          # Tagging
          attribute :vpc_tags, Types::Hash.default({})
          attribute :public_subnet_tags, Types::Hash.default({})
          attribute :private_subnet_tags, Types::Hash.default({})
          attribute :common_tags, Types::Hash.default({})
          
          # Naming
          attribute :name_prefix, Types::String.optional.default(nil)
        end
      end
    end
  end
end