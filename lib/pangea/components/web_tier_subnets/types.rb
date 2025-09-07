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
    module WebTierSubnets
      module Types
        # WebTierSubnets component attributes with comprehensive validation
        class WebTierSubnetsAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :vpc_ref, Components::Types::VpcReference
          attribute :subnet_cidrs, Components::Types::SubnetCidrBlocks
          attribute :availability_zones, Components::Types::AvailabilityZones
          attribute :enable_public_ips, Components::Types::Bool.default(true)
          attribute :enable_ipv6, Components::Types::Bool.default(false)
          attribute :create_internet_gateway, Components::Types::Bool.default(true)
          attribute :create_nat_gateway, Components::Types::Bool.default(false)
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :subnet_tags, Resources::Types::AwsTags.default({}.freeze)
          attribute :high_availability, Components::Types::HighAvailabilityConfig.default({}.freeze)
          attribute :load_balancing, Components::Types::LoadBalancingConfig.default({}.freeze)
          
          # Custom validation for web tier subnet configuration
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate subnet count matches AZ count for even distribution
            subnet_cidrs = attrs[:subnet_cidrs] || []
            availability_zones = attrs[:availability_zones] || []
            
            if attrs[:high_availability] && attrs[:high_availability][:distribute_evenly]
              if subnet_cidrs.length != availability_zones.length
                raise Dry::Struct::Error, "Even distribution requires subnet count (#{subnet_cidrs.length}) to equal AZ count (#{availability_zones.length})"
              end
            end
            
            # Validate minimum subnet count for high availability
            if attrs[:high_availability] && attrs[:high_availability][:multi_az]
              min_azs = attrs[:high_availability][:min_availability_zones] || 2
              if availability_zones.length < min_azs
                raise Dry::Struct::Error, "High availability requires at least #{min_azs} availability zones"
              end
              if subnet_cidrs.length < min_azs
                raise Dry::Struct::Error, "High availability requires at least #{min_azs} subnets"
              end
            end
            
            # Validate IPv6 configuration (future enhancement)
            if attrs[:enable_ipv6] && !attrs[:enable_public_ips]
              raise Dry::Struct::Error, "IPv6 subnets typically require public IP assignment capability"
            end
            
            # Validate load balancer configuration requirements
            if attrs[:load_balancing] && attrs[:load_balancing][:scheme] == 'internet-facing'
              unless attrs[:enable_public_ips] && attrs[:create_internet_gateway]
                raise Dry::Struct::Error, "Internet-facing load balancer requires public IPs and Internet Gateway"
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def subnet_count
            subnet_cidrs.length
          end
          
          def az_count
            availability_zones.length
          end
          
          def subnets_per_az
            return 1 if az_count == 0
            (subnet_count.to_f / az_count).ceil
          end
          
          def is_highly_available?
            high_availability[:multi_az] && az_count >= 2 && subnet_count >= 2
          end
          
          def load_balancer_ready?
            case load_balancing[:scheme]
            when 'internet-facing'
              enable_public_ips && create_internet_gateway
            when 'internal'
              true
            else
              enable_public_ips && create_internet_gateway
            end
          end
          
          def distribution_pattern
            if high_availability[:distribute_evenly] && subnet_count == az_count
              'one_per_az'
            elsif subnet_count % az_count == 0
              'even_distribution'
            elsif subnet_count > az_count
              'uneven_distribution'
            else
              'insufficient_subnets'
            end
          end
          
          def tier_configuration
            features = []
            features << 'PUBLIC_ACCESS' if enable_public_ips
            features << 'INTERNET_GATEWAY' if create_internet_gateway
            features << 'NAT_GATEWAY' if create_nat_gateway
            features << 'IPV6_ENABLED' if enable_ipv6
            features << 'MULTI_AZ' if is_highly_available?
            features << 'LOAD_BALANCER_READY' if load_balancer_ready?
            
            {
              features: features,
              pattern: distribution_pattern,
              subnets_per_az: subnets_per_az,
              high_availability: is_highly_available?
            }
          end
          
          def estimated_capacity_per_subnet
            # Estimate instances that can fit in each subnet based on CIDR
            subnet_cidrs.map do |cidr|
              prefix = cidr.split('/')[1].to_i
              total_ips = 2**(32 - prefix)
              usable_ips = total_ips - 5  # AWS reserves 5 IPs per subnet
              
              # Assume some IPs reserved for load balancers, NAT, etc.
              available_for_instances = usable_ips - 10
              [available_for_instances, 0].max
            end
          end
          
          def total_estimated_capacity
            estimated_capacity_per_subnet.sum
          end
          
          def web_tier_profile
            profile = []
            profile << 'Internet Gateway' if create_internet_gateway
            profile << 'Public IP Assignment' if enable_public_ips
            profile << 'IPv6 Support' if enable_ipv6
            profile << 'NAT Gateway' if create_nat_gateway
            profile << 'High Availability' if is_highly_available?
            profile << 'Load Balancer Ready' if load_balancer_ready?
            
            case profile.length
            when 0..2 then 'basic'
            when 3..4 then 'standard'
            when 5..6 then 'advanced'
            else 'enterprise'
            end
          end
          
          def compliance_features
            features = []
            features << 'Multi-AZ Distribution' if is_highly_available?
            features << 'Internet Gateway Routing' if create_internet_gateway
            features << 'Public IP Management' if enable_public_ips
            features << 'Load Balancer Integration' if load_balancer_ready?
            features << 'High Availability Architecture' if is_highly_available?
            features
          end
        end
      end
    end
  end
end