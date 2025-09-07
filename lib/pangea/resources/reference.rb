# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    # Resource reference object returned by resource functions
    # Provides access to resource attributes, outputs, and computed properties
    class ResourceReference < Dry::Struct
      
      attribute :type, Types::String           # aws_vpc, aws_subnet, etc.
      attribute :name, Types::Symbol           # Resource name
      attribute :resource_attributes, Types::Hash       # Original attributes passed to function
      attribute :outputs, Types::Hash.default({}.freeze)  # Available outputs for this resource type
      
      # Generate terraform reference for any attribute
      def ref(attribute_name)
        "${#{type}.#{name}.#{attribute_name}}"
      end
      
      # Alias for ref - more natural syntax
      def [](attribute_name)
        ref(attribute_name)
      end
      
      # Access to common outputs with friendly names
      def id
        ref(:id)
      end
      
      def arn
        ref(:arn)
      end
      
      # Resource-specific computed properties
      def computed_attributes
        @computed_attributes ||= case type
        when 'aws_vpc'
          VpcComputedAttributes.new(self)
        when 'aws_subnet'
          SubnetComputedAttributes.new(self)
        when 'aws_instance'
          InstanceComputedAttributes.new(self)
        else
          BaseComputedAttributes.new(self)
        end
      end
      
      # Method delegation to computed attributes
      def method_missing(method_name, *args, &block)
        if computed_attributes.respond_to?(method_name)
          computed_attributes.public_send(method_name, *args, &block)
        else
          super
        end
      end
      
      def respond_to_missing?(method_name, include_private = false)
        computed_attributes.respond_to?(method_name, include_private) || super
      end
      
      # Convert to hash for terraform-synthesizer integration
      def to_h
        {
          type: type,
          name: name,
          attributes: resource_attributes,  # Use 'attributes' as key for compatibility
          outputs: outputs
        }
      end
    end
    
    # Base computed attributes - common to all resources
    class BaseComputedAttributes
      attr_reader :resource_ref
      
      def initialize(resource_ref)
        @resource_ref = resource_ref
      end
      
      # Common terraform attributes available on all resources
      def id
        resource_ref.ref(:id)
      end
      
      def terraform_resource_name
        "#{resource_ref.type}.#{resource_ref.name}"
      end
      
      def tags
        resource_ref.resource_attributes[:tags] || {}
      end
    end
    
    # VPC-specific computed attributes
    class VpcComputedAttributes < BaseComputedAttributes
      # VPC-specific terraform outputs
      def cidr_block
        resource_ref.ref(:cidr_block)
      end
      
      def default_security_group_id
        resource_ref.ref(:default_security_group_id)
      end
      
      def default_route_table_id
        resource_ref.ref(:default_route_table_id)
      end
      
      def default_network_acl_id
        resource_ref.ref(:default_network_acl_id)
      end
      
      def dhcp_options_id
        resource_ref.ref(:dhcp_options_id)
      end
      
      def main_route_table_id
        resource_ref.ref(:main_route_table_id)
      end
      
      def owner_id
        resource_ref.ref(:owner_id)
      end
      
      # Computed helper methods
      def is_private_cidr?
        cidr = resource_ref.resource_attributes[:cidr_block]
        return false unless cidr
        
        ip_parts = cidr.split('/')[0].split('.').map(&:to_i)
        
        # 10.0.0.0/8
        return true if ip_parts[0] == 10
        
        # 172.16.0.0/12
        return true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
        
        # 192.168.0.0/16
        return true if ip_parts[0] == 192 && ip_parts[1] == 168
        
        false
      end
      
      def estimated_subnet_capacity
        cidr_parts = resource_ref.resource_attributes[:cidr_block].split('/')
        vpc_size = cidr_parts[1].to_i
        
        # Estimate how many /24 subnets can fit
        case vpc_size
        when 16 then 256
        when 17 then 128
        when 18 then 64
        when 19 then 32
        when 20 then 16
        when 21 then 8
        when 22 then 4
        when 23 then 2
        when 24 then 1
        else 0
        end
      end
    end
    
    # Subnet-specific computed attributes
    class SubnetComputedAttributes < BaseComputedAttributes
      def availability_zone
        resource_ref.ref(:availability_zone)
      end
      
      def availability_zone_id
        resource_ref.ref(:availability_zone_id)
      end
      
      def cidr_block
        resource_ref.ref(:cidr_block)
      end
      
      def vpc_id
        resource_ref.ref(:vpc_id)
      end
      
      def is_public?
        resource_ref.resource_attributes[:map_public_ip_on_launch] == true
      end
      
      def is_private?
        !is_public?
      end
      
      def subnet_type
        is_public? ? 'public' : 'private'
      end
      
      # Calculate approximate IP capacity
      def ip_capacity
        cidr_parts = resource_ref.resource_attributes[:cidr_block].split('/')
        subnet_size = cidr_parts[1].to_i
        
        # AWS reserves 5 IPs per subnet
        total_ips = 2**(32 - subnet_size)
        total_ips - 5
      end
    end
    
    # EC2 Instance-specific computed attributes
    class InstanceComputedAttributes < BaseComputedAttributes
      def public_ip
        resource_ref.ref(:public_ip)
      end
      
      def private_ip
        resource_ref.ref(:private_ip)
      end
      
      def public_dns
        resource_ref.ref(:public_dns)
      end
      
      def private_dns
        resource_ref.ref(:private_dns)
      end
      
      def instance_state
        resource_ref.ref(:instance_state)
      end
      
      def subnet_id
        resource_ref.ref(:subnet_id)
      end
      
      def vpc_security_group_ids
        resource_ref.ref(:vpc_security_group_ids)
      end
      
      def instance_type
        resource_ref.resource_attributes[:instance_type]
      end
      
      def ami
        resource_ref.resource_attributes[:ami]
      end
      
      # Helper methods
      def will_have_public_ip?
        # If explicitly set to false, respect that
        return false if resource_ref.resource_attributes[:associate_public_ip_address] == false
        
        # Otherwise, true if explicitly set to true or in a public subnet
        resource_ref.resource_attributes[:associate_public_ip_address] == true ||
          resource_ref.resource_attributes[:subnet_id]&.include?('public')
      end
      
      def compute_family
        instance_type = resource_ref.resource_attributes[:instance_type]
        instance_type.split('.').first if instance_type
      end
      
      def compute_size
        instance_type = resource_ref.resource_attributes[:instance_type]
        instance_type.split('.').last if instance_type
      end
    end
  end
end