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
      # Type-safe attributes for AwsVpnGateway resources
      class VpnGatewayAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Optional attributes
        attribute :vpc_id, Resources::Types::String.optional
        attribute :availability_zone, Resources::Types::AwsAvailabilityZone.optional
        attribute :type, Resources::Types::VpnGatewayType.default('ipsec.1')
        attribute :amazon_side_asn, Resources::Types::BgpAsn.optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = attributes.is_a?(Hash) ? attributes : {}
          
          # Validate VPC ID format if provided
          if attrs[:vpc_id]
            unless attrs[:vpc_id].match(/\Avpc-[0-9a-f]{8,17}\z/)
              raise Dry::Struct::Error, "vpc_id must be a valid VPC ID (vpc-*)"
            end
          end
          
          # Validate Amazon-side ASN if provided
          if attrs[:amazon_side_asn]
            # Amazon side ASNs have specific valid ranges
            asn = attrs[:amazon_side_asn]
            
            # Valid ranges for Amazon side ASNs:
            # 64512 to 65534 (16-bit private ASNs)
            # 4200000000 to 4294967294 (32-bit private ASNs)
            valid_16bit = (64512..65534).include?(asn)
            valid_32bit = (4200000000..4294967294).include?(asn)
            
            unless valid_16bit || valid_32bit
              raise Dry::Struct::Error, "amazon_side_asn must be in range 64512-65534 or 4200000000-4294967294"
            end
          end
          
          super(attrs)
        end

        # Computed properties
        def has_vpc_attachment?
          !vpc_id.nil?
        end
        
        def uses_custom_asn?
          !amazon_side_asn.nil?
        end
        
        def is_multi_az_capable?
          availability_zone.nil?  # No specific AZ means multi-AZ
        end
        
        def attachment_type
          return 'vpc' if vpc_id
          'detached'
        end
      end
    end
      end
    end
  end
end