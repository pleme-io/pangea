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
        # VPC resource attributes with validation
        class VpcAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :cidr_block, Resources::Types::CidrBlock
          attribute :enable_dns_hostnames, Resources::Types::Bool.default(true)
          attribute :enable_dns_support, Resources::Types::Bool.default(true)
          attribute :instance_tenancy, Resources::Types::InstanceTenancy
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for CIDR block subnet size
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate CIDR block is not too small for practical use
            if attrs[:cidr_block]
              cidr_parts = attrs[:cidr_block].split('/')
              subnet_size = cidr_parts[1].to_i
              
              if subnet_size > 28
                raise Dry::Struct::Error, "CIDR block #{attrs[:cidr_block]} is too small (>/28). VPCs should typically be /16 to /28."
              end
              
              if subnet_size < 16
                raise Dry::Struct::Error, "CIDR block #{attrs[:cidr_block]} is too large (</16). AWS VPCs support /16 to /28."
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def subnet_count_estimate
            cidr_parts = cidr_block.split('/')
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
          
          def is_rfc1918_private?
            # Check if CIDR is in private address space
            ip_parts = cidr_block.split('/')[0].split('.').map(&:to_i)
            
            # 10.0.0.0/8
            return true if ip_parts[0] == 10
            
            # 172.16.0.0/12
            return true if ip_parts[0] == 172 && (16..31).include?(ip_parts[1])
            
            # 192.168.0.0/16
            return true if ip_parts[0] == 192 && ip_parts[1] == 168
            
            false
          end
        end
      end
    end
  end
end