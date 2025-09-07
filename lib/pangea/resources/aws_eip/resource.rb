# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_eip/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Elastic IP with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Resource attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_eip(name, attributes = {})
        # Validate attributes using dry-struct
        attrs = AWS::Types::EipAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_eip, name) do
          # Domain is always specified (default is vpc)
          domain attrs.domain
          
          # Instance association
          instance attrs.instance if attrs.instance
          
          # Network interface association
          network_interface attrs.network_interface if attrs.network_interface
          
          # Private IP association (requires network_interface)
          associate_with_private_ip attrs.associate_with_private_ip if attrs.associate_with_private_ip
          
          # Customer-owned IP pool
          customer_owned_ipv4_pool attrs.customer_owned_ipv4_pool if attrs.customer_owned_ipv4_pool
          
          # Network border group
          network_border_group attrs.network_border_group if attrs.network_border_group
          
          # Public IPv4 pool
          public_ipv4_pool attrs.public_ipv4_pool if attrs.public_ipv4_pool
          
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
        ref = ResourceReference.new(
          type: 'aws_eip',
          name: name,
          resource_attributes: attrs.to_h,
          outputs: {
            id: "${aws_eip.#{name}.id}",
            allocation_id: "${aws_eip.#{name}.allocation_id}",
            association_id: "${aws_eip.#{name}.association_id}",
            carrier_ip: "${aws_eip.#{name}.carrier_ip}",
            customer_owned_ip: "${aws_eip.#{name}.customer_owned_ip}",
            customer_owned_ipv4_pool: "${aws_eip.#{name}.customer_owned_ipv4_pool}",
            domain: "${aws_eip.#{name}.domain}",
            instance: "${aws_eip.#{name}.instance}",
            network_border_group: "${aws_eip.#{name}.network_border_group}",
            network_interface: "${aws_eip.#{name}.network_interface}",
            private_dns: "${aws_eip.#{name}.private_dns}",
            private_ip: "${aws_eip.#{name}.private_ip}",
            public_dns: "${aws_eip.#{name}.public_dns}",
            public_ip: "${aws_eip.#{name}.public_ip}",
            public_ipv4_pool: "${aws_eip.#{name}.public_ipv4_pool}",
            tags_all: "${aws_eip.#{name}.tags_all}",
            vpc: "${aws_eip.#{name}.vpc}"
          }
        )
        
        # Add computed properties via method delegation
        ref.define_singleton_method(:vpc?) { attrs.vpc? }
        ref.define_singleton_method(:associated?) { attrs.associated? }
        ref.define_singleton_method(:customer_owned?) { attrs.customer_owned? }
        ref.define_singleton_method(:association_type) { attrs.association_type }
        
        ref
      end
    end
  end
end

# Note: Registration handled by main aws.rb module