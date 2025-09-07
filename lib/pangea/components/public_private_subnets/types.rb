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
require 'pangea/components/types'

module Pangea
  module Components
    module PublicPrivateSubnets
      module Types
        # PublicPrivateSubnets component attributes with comprehensive validation
        class PublicPrivateSubnetsAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :vpc_ref, Components::Types::VpcReference
          attribute :public_cidrs, Components::Types::SubnetCidrBlocks
          attribute :private_cidrs, Components::Types::SubnetCidrBlocks
          attribute :availability_zones, Components::Types::AvailabilityZones.optional
          attribute :create_nat_gateway, Components::Types::Bool.default(true)
          attribute :nat_gateway_type, Resources::Types::String.enum('single', 'per_az').default('per_az')
          attribute :enable_nat_gateway_monitoring, Components::Types::Bool.default(true)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :public_subnet_tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :private_subnet_tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :high_availability, Components::Types::HighAvailabilityConfig.default({}.freeze)
          
          # Custom validation for subnet configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate CIDR blocks don't overlap
            public_cidrs = attrs[:public_cidrs] || []
            private_cidrs = attrs[:private_cidrs] || []
            all_cidrs = public_cidrs + private_cidrs
            
            if all_cidrs.uniq.length != all_cidrs.length
              raise Dry::Struct::Error, "Duplicate CIDR blocks found between public and private subnets"
            end
            
            # Validate availability zones match subnet counts in HA mode
            if attrs[:high_availability] && attrs[:high_availability][:multi_az]
              min_azs = attrs[:high_availability][:min_availability_zones] || 2
              if attrs[:availability_zones] && attrs[:availability_zones].length < min_azs
                raise Dry::Struct::Error, "High availability requires at least #{min_azs} availability zones"
              end
            end
            
            # Validate subnet distribution for HA
            if attrs[:high_availability] && attrs[:high_availability][:distribute_evenly]
              az_count = attrs[:availability_zones]&.length || 2
              if public_cidrs.length % az_count != 0 || private_cidrs.length % az_count != 0
                raise Dry::Struct::Error, "Even distribution requires subnet count to be divisible by AZ count"
              end
            end
            
            # Validate NAT gateway configuration
            if attrs[:nat_gateway_type] == 'per_az' && attrs[:availability_zones]
              if private_cidrs.length < attrs[:availability_zones].length
                raise Dry::Struct::Error, "NAT gateway per AZ requires at least one private subnet per AZ"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def subnet_pairs_count
            [public_cidrs.length, private_cidrs.length].min
          end
          
          def total_subnets_count
            public_cidrs.length + private_cidrs.length
          end
          
          def nat_gateway_count
            return 0 unless create_nat_gateway
            
            case nat_gateway_type
            when 'single' then 1
            when 'per_az' then availability_zones&.length || 1
            else 1
            end
          end
          
          def estimated_monthly_nat_cost
            # Basic NAT Gateway cost estimate: $45/month per gateway + data processing
            base_cost_per_gateway = 45.0
            nat_gateway_count * base_cost_per_gateway
          end
          
          def high_availability_level
            return 'none' unless high_availability[:multi_az]
            
            az_count = availability_zones&.length || 1
            case az_count
            when 1 then 'none'
            when 2 then 'basic'
            when 3.. then 'high'
            else 'none'
            end
          end
          
          def subnet_distribution_strategy
            if high_availability[:distribute_evenly]
              'even_distribution'
            elsif availability_zones && availability_zones.length > 1
              'multi_az_manual'
            else
              'single_az'
            end
          end
          
          def networking_pattern
            case [public_cidrs.length > 0, private_cidrs.length > 0]
            when [true, true] then 'hybrid_public_private'
            when [true, false] then 'public_only'
            when [false, true] then 'private_only'
            else 'invalid'
            end
          end
          
          def security_profile
            features = []
            features << 'NAT_GATEWAY_ISOLATION' if create_nat_gateway && nat_gateway_type == 'per_az'
            features << 'PRIVATE_SUBNET_ISOLATION' if private_cidrs.any?
            features << 'MULTI_AZ_REDUNDANCY' if high_availability[:multi_az]
            features << 'MONITORING_ENABLED' if enable_nat_gateway_monitoring
            
            case features.length
            when 0..1 then 'basic'
            when 2..3 then 'enhanced'
            when 4.. then 'maximum'
            end
          end
        end
      end
    end
  end
end