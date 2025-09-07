# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Elastic IP resources
        class EipAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Domain for the EIP ("vpc" or "standard")
          attribute :domain, Resources::Types::String.default("vpc").enum("vpc", "standard")
          
          # Associate EIP with instance (optional)
          attribute :instance, Resources::Types::String.optional
          
          # Associate EIP with network interface (optional)
          attribute :network_interface, Resources::Types::String.optional
          
          # Associate EIP with private IP (optional)
          attribute :associate_with_private_ip, Resources::Types::String.optional
          
          # Use a customer-owned IP pool (optional)
          attribute :customer_owned_ipv4_pool, Resources::Types::String.optional
          
          # Network border group (optional)
          attribute :network_border_group, Resources::Types::String.optional
          
          # Public IPv4 pool (optional)
          attribute :public_ipv4_pool, Resources::Types::String.optional
          
          # Tags to apply to the resource
          attribute :tags, Resources::Types::AwsTags.default({})

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            
            # Cannot specify both instance and network_interface
            if attrs.instance && attrs.network_interface
              raise Dry::Struct::Error, "Cannot specify both 'instance' and 'network_interface'"
            end
            
            # associate_with_private_ip requires network_interface
            if attrs.associate_with_private_ip && !attrs.network_interface
              raise Dry::Struct::Error, "'associate_with_private_ip' requires 'network_interface' to be specified"
            end
            
            # customer_owned_ipv4_pool requires specific configuration
            if attrs.customer_owned_ipv4_pool && attrs.public_ipv4_pool
              raise Dry::Struct::Error, "Cannot specify both 'customer_owned_ipv4_pool' and 'public_ipv4_pool'"
            end
            
            attrs
          end

          # Check if EIP is for VPC
          def vpc?
            domain == "vpc"
          end
          
          # Check if EIP is associated
          def associated?
            !instance.nil? || !network_interface.nil?
          end
          
          # Check if using customer-owned IP
          def customer_owned?
            !customer_owned_ipv4_pool.nil?
          end
          
          # Determine the association type
          def association_type
            if instance
              :instance
            elsif network_interface
              :network_interface
            else
              :unassociated
            end
          end
        end
      end
    end
  end
end