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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Transit Gateway resource attributes with validation
        class TransitGatewayAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute? :amazon_side_asn, Resources::Types::TransitGatewayAsn.optional
          attribute? :auto_accept_shared_attachments, Resources::Types::String.enum('enable', 'disable').default('disable')
          attribute? :default_route_table_association, Resources::Types::TransitGatewayDefaultRouteTableAssociation
          attribute? :default_route_table_propagation, Resources::Types::TransitGatewayDefaultRouteTablePropagation
          attribute? :description, Resources::Types::String.optional
          attribute? :dns_support, Resources::Types::TransitGatewayDnsSupport
          attribute? :multicast_support, Resources::Types::TransitGatewayMulticastSupport
          attribute? :vpn_ecmp_support, Resources::Types::TransitGatewayVpnEcmpSupport
          attribute? :tags, Resources::Types::AwsTags
          
          # Custom validation for Transit Gateway configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate ASN if provided
            if attrs[:amazon_side_asn]
              asn = attrs[:amazon_side_asn]
              
              # Check against common public ASNs that shouldn't be used for private networks
              public_asns = [
                1, 2, 3, 4, 5, 6, 7, 8, 9, 10, # Early Internet ASNs
                15169, # Google
                16509, # Amazon
                32934, # Facebook
                13335  # Cloudflare
              ]
              
              if public_asns.include?(asn)
                raise Dry::Struct::Error, "ASN #{asn} is a public ASN and should not be used for private Transit Gateways"
              end
            end
            
            # Validate multicast and default route table interaction
            if attrs[:multicast_support] == 'enable'
              if attrs[:default_route_table_association] == 'disable'
                raise Dry::Struct::Error, "Multicast support requires default route table association to be enabled"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def supports_cross_region_peering?
            # All Transit Gateways support cross-region peering
            true
          end
          
          def supports_dx_gateway_attachment?
            # All Transit Gateways support Direct Connect Gateway attachments
            true
          end
          
          def estimated_monthly_cost
            # Base cost for Transit Gateway: $36/month
            base_cost = 36.0
            
            # Additional costs would be calculated based on:
            # - Data processing: $0.02 per GB
            # - VPC attachments: $36.50 per month per attachment
            # - VPN attachments: $36.50 per month per attachment
            # - Direct Connect Gateway attachments: $36.50 per month per attachment
            
            {
              base_monthly_cost: base_cost,
              currency: 'USD',
              note: 'Base cost only. Additional charges apply for attachments and data processing.'
            }
          end
          
          def security_considerations
            considerations = []
            
            if auto_accept_shared_attachments == 'enable'
              considerations << "Auto-accept shared attachments is enabled - ensure proper resource sharing policies are in place"
            end
            
            if default_route_table_association == 'enable'
              considerations << "Default route table association is enabled - all attachments will be associated with the default route table"
            end
            
            if default_route_table_propagation == 'enable'
              considerations << "Default route table propagation is enabled - routes will be automatically propagated from all attachments"
            end
            
            considerations
          end
          
          def is_hub_and_spoke_optimized?
            # Hub and spoke is optimized when using default route tables
            default_route_table_association == 'enable' && default_route_table_propagation == 'enable'
          end
        end
      end
    end
  end
end