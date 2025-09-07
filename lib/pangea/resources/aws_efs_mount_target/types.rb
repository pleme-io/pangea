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
        # EFS Mount Target resource attributes with validation
        class EfsMountTargetAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :file_system_id, Resources::Types::String
          attribute :subnet_id, Resources::Types::String
          
          # Optional attributes  
          attribute :ip_address, Resources::Types::String.optional
          attribute :security_groups, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate IP address format if provided
            if attrs[:ip_address]
              ip = attrs[:ip_address]
              unless ip.match?(/\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/)
                raise Dry::Struct::Error, "ip_address must be a valid IPv4 address, got '#{ip}'"
              end
              
              # Check if it's in private IP range (as mount targets are in VPC)
              ip_parts = ip.split('.').map(&:to_i)
              is_private = false
              
              # 10.0.0.0/8
              is_private = true if ip_parts[0] == 10
              
              # 172.16.0.0/12  
              is_private = true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
              
              # 192.168.0.0/16
              is_private = true if ip_parts[0] == 192 && ip_parts[1] == 168
              
              unless is_private
                raise Dry::Struct::Error, "ip_address must be in private IP range (10.0.0.0/8, 172.16.0.0/12, or 192.168.0.0/16)"
              end
            end
            
            # Validate security groups array
            if attrs[:security_groups] && attrs[:security_groups].length > 5
              raise Dry::Struct::Error, "Maximum of 5 security groups allowed for EFS mount targets"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def has_custom_ip?
            !ip_address.nil?
          end
          
          def security_group_count
            security_groups.length
          end
          
          def is_fully_configured?
            !file_system_id.empty? && !subnet_id.empty? && !security_groups.empty?
          end
          
          def estimated_data_transfer_cost_per_gb
            # EFS mount targets don't have direct costs, but data transfer applies
            # Regional: $0.01 per GB for cross-AZ access
            # One Zone: No cross-AZ charges within same AZ
            {
              cross_az_data_transfer: 0.01,
              same_az_data_transfer: 0.00,
              note: "Actual costs depend on file system type and access patterns"
            }
          end
        end
      end
    end
  end
end