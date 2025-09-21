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
      # Type-safe attributes for AwsCustomerGateway resources
      class CustomerGatewayAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        # Required attributes
        attribute :bgp_asn, Resources::Types::BgpAsn
        attribute :ip_address, Resources::Types::PublicIpAddress
        attribute :type, Resources::Types::VpnGatewayType
        
        # Optional attributes
        attribute :certificate_arn, Resources::Types::String.optional
        attribute :device_name, Resources::Types::String.optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = attributes.is_a?(Hash) ? attributes : {}
          
          # Validate BGP ASN for customer gateway
          if attrs[:bgp_asn]
            validate_bgp_asn(attrs[:bgp_asn])
          end
          
          # Validate certificate ARN format if provided
          if attrs[:certificate_arn]
            validate_certificate_arn(attrs[:certificate_arn])
          end
          
          # Validate device name length if provided
          if attrs[:device_name]
            if attrs[:device_name].length > 255
              raise Dry::Struct::Error, "device_name must be 255 characters or less"
            end
          end
          
          super(attrs)
        end

        # Computed properties
        def uses_certificate_authentication?
          !certificate_arn.nil?
        end
        
        def has_device_name?
          !device_name.nil?
        end
        
        def is_16bit_asn?
          bgp_asn <= 65535
        end
        
        def is_32bit_asn?
          bgp_asn > 65535
        end
        
        def gateway_type
          type
        end
        
        private
        
        def self.validate_bgp_asn(asn)
          # Customer gateway BGP ASNs have different constraints than Amazon-side ASNs
          # Valid ranges: 1-65534 (16-bit), 4200000000-4294967294 (32-bit)
          # Exclude AWS reserved ASNs
          aws_reserved = [7224, 9059, 10124, 17943]
          
          if aws_reserved.include?(asn)
            raise Dry::Struct::Error, "BGP ASN #{asn} is reserved by AWS and cannot be used for customer gateways"
          end
          
          # Check valid ranges
          valid_16bit = (1..65534).include?(asn) && !aws_reserved.include?(asn)
          valid_32bit = (4200000000..4294967294).include?(asn)
          
          unless valid_16bit || valid_32bit
            raise Dry::Struct::Error, "bgp_asn must be in range 1-65534 (excluding AWS reserved) or 4200000000-4294967294"
          end
        end
        
        def self.validate_certificate_arn(arn)
          # AWS Certificate Manager ARN format
          arn_pattern = /\Aarn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate\/[a-f0-9-]{36}\z/
          
          unless arn.match(arn_pattern)
            raise Dry::Struct::Error, "certificate_arn must be a valid AWS Certificate Manager ARN"
          end
        end
      end
    end
      end
    end
  end
end