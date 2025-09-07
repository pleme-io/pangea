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
        # WAF v2 IP Set attributes with validation
        class WafV2IpSetAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :scope, Resources::Types::WafV2Scope
          attribute :ip_address_version, Resources::Types::WafV2IpAddressVersion
          attribute :description, String.constrained(max_size: 256).optional
          attribute :addresses, Array.of(String).constrained(min_size: 1, max_size: 10000)
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate IP addresses match the specified version
            if attrs[:addresses] && attrs[:ip_address_version]
              attrs[:addresses].each do |address|
                if attrs[:ip_address_version] == 'IPV4'
                  validate_ipv4_address(address)
                elsif attrs[:ip_address_version] == 'IPV6'
                  validate_ipv6_address(address)
                end
              end
            end
            
            # Check for duplicate addresses
            if attrs[:addresses]
              duplicates = attrs[:addresses].group_by(&:itself).select { |_, v| v.size > 1 }.keys
              unless duplicates.empty?
                raise Dry::Struct::Error, "Duplicate IP addresses found: #{duplicates.join(', ')}"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def address_count
            addresses.size
          end
          
          def has_cidr_blocks?
            addresses.any? { |addr| addr.include?('/') }
          end
          
          def has_individual_ips?
            addresses.any? { |addr| !addr.include?('/') }
          end
          
          def estimated_ip_count
            addresses.sum do |address|
              if address.include?('/')
                # CIDR block - estimate number of IPs
                prefix_length = address.split('/')[1].to_i
                if ip_address_version == 'IPV4'
                  2**(32 - prefix_length)
                else # IPV6
                  # For IPv6, just return 1 for practical purposes
                  1
                end
              else
                # Individual IP
                1
              end
            end
          end
          
          private
          
          def self.validate_ipv4_address(address)
            if address.include?('/')
              ip, prefix = address.split('/')
              prefix_int = prefix.to_i
              
              unless (0..32).include?(prefix_int)
                raise Dry::Struct::Error, "Invalid IPv4 prefix length: #{prefix}. Must be 0-32."
              end
              
              validate_ipv4_ip(ip)
            else
              validate_ipv4_ip(address)
            end
          end
          
          def self.validate_ipv4_ip(ip)
            parts = ip.split('.')
            unless parts.size == 4 && parts.all? { |part| part.match?(/\A\d+\z/) && (0..255).include?(part.to_i) }
              raise Dry::Struct::Error, "Invalid IPv4 address: #{ip}"
            end
          end
          
          def self.validate_ipv6_address(address)
            if address.include?('/')
              ip, prefix = address.split('/')
              prefix_int = prefix.to_i
              
              unless (0..128).include?(prefix_int)
                raise Dry::Struct::Error, "Invalid IPv6 prefix length: #{prefix}. Must be 0-128."
              end
              
              validate_ipv6_ip(ip)
            else
              validate_ipv6_ip(address)
            end
          end
          
          def self.validate_ipv6_ip(ip)
            # Basic IPv6 validation - expanded for brevity
            unless ip.match?(/\A([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}\z/) || ip == '::'
              raise Dry::Struct::Error, "Invalid IPv6 address: #{ip}"
            end
          end
        end
      end
    end
  end
end