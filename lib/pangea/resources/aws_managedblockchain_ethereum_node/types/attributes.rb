# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Managed Blockchain Ethereum Node resources
        class ManagedBlockchainEthereumNodeAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # Network ID (required)
          attribute :network_id, Resources::Types::String.enum(
            'n-ethereum-mainnet',
            'n-ethereum-goerli',
            'n-ethereum-rinkeby'
          )

          # Node configuration (required)
          attribute :node_configuration, Resources::Types::Hash.schema(
            instance_type: Resources::Types::String.enum(
              'bc.t3.small', 'bc.t3.medium', 'bc.t3.large', 'bc.t3.xlarge',
              'bc.m5.large', 'bc.m5.xlarge', 'bc.m5.2xlarge', 'bc.m5.4xlarge',
              'bc.c5.large', 'bc.c5.xlarge', 'bc.c5.2xlarge', 'bc.c5.4xlarge',
              'bc.r5.large', 'bc.r5.xlarge', 'bc.r5.2xlarge', 'bc.r5.4xlarge'
            ),
            availability_zone?: Resources::Types::String.optional,
            subnet_id?: Resources::Types::String.optional
          )

          # Client request token (optional)
          attribute? :client_request_token, Resources::Types::String.optional

          # Tags (optional)
          attribute? :tags, Resources::Types::Hash.schema(
            Resources::Types::String => Resources::Types::String
          ).optional

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_availability_zone(attrs)
            validate_subnet_id(attrs)
            validate_client_request_token(attrs)
            validate_instance_type_for_network(attrs)
            attrs
          end

          def self.validate_availability_zone(attrs)
            az = attrs.node_configuration[:availability_zone]
            return unless az
            return if az.match?(/\A[a-z0-9\-]+[a-z]\z/)
            raise Dry::Struct::Error, "availability_zone must be a valid AWS availability zone format"
          end

          def self.validate_subnet_id(attrs)
            subnet_id = attrs.node_configuration[:subnet_id]
            return unless subnet_id
            return if subnet_id.match?(/\Asubnet-[a-f0-9]{8,17}\z/)
            raise Dry::Struct::Error, "subnet_id must be a valid AWS subnet ID format"
          end

          def self.validate_client_request_token(attrs)
            token = attrs.client_request_token
            return unless token
            return if token.match?(/\A[a-zA-Z0-9\-_]{1,64}\z/)
            raise Dry::Struct::Error, "client_request_token must be 1-64 characters"
          end

          def self.validate_instance_type_for_network(attrs)
            return unless attrs.network_id == 'n-ethereum-mainnet'
            instance_type = attrs.node_configuration[:instance_type]
            return unless instance_type.start_with?('bc.t3.small', 'bc.t3.medium')
            raise Dry::Struct::Error, "Ethereum mainnet requires at least bc.t3.large instance type"
          end
        end
      end
    end
  end
end
