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
        # AppStream Fleet resource attributes with validation
        class AppstreamFleetAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 100,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/
          )
          
          attribute :compute_capacity, ComputeCapacityType
          attribute :instance_type, Resources::Types::String.constrained(
            format: /\Astream\.[a-z0-9]+\.[a-z0-9]+\z/
          )
          
          # Optional attributes
          attribute :description, Resources::Types::String.constrained(
            max_size: 256
          ).optional
          
          attribute :display_name, Resources::Types::String.constrained(
            max_size: 100
          ).optional
          
          attribute :vpc_config, VpcConfigType.optional
          attribute :domain_join_info, DomainJoinInfoType.optional
          attribute :fleet_type, Resources::Types::String.enum(
            'ALWAYS_ON',
            'ON_DEMAND'
          ).default('ON_DEMAND')
          
          attribute :enable_default_internet_access, Resources::Types::Bool.default(true)
          attribute :image_name, Resources::Types::String.optional
          attribute :image_arn, Resources::Types::String.optional
          attribute :idle_disconnect_timeout_in_seconds, Resources::Types::Integer.constrained(
            gteq: 0,
            lteq: 3600
          ).default(0)
          
          attribute :disconnect_timeout_in_seconds, Resources::Types::Integer.constrained(
            gteq: 60,
            lteq: 360000
          ).default(900)
          
          attribute :max_user_duration_in_seconds, Resources::Types::Integer.constrained(
            gteq: 600,
            lteq: 360000
          ).default(57600)  # 16 hours
          
          attribute :stream_view, Resources::Types::String.enum(
            'APP',
            'DESKTOP'
          ).default('APP')
          
          attribute :tags, Resources::Types::AwsTags
          
          # Validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Must specify either image_name or image_arn
            if !attrs[:image_name] && !attrs[:image_arn]
              raise Dry::Struct::Error, "Either image_name or image_arn must be specified"
            end
            
            if attrs[:image_name] && attrs[:image_arn]
              raise Dry::Struct::Error, "Cannot specify both image_name and image_arn"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def always_on?
            fleet_type == 'ALWAYS_ON'
          end
          
          def on_demand?
            fleet_type == 'ON_DEMAND'
          end
          
          def max_concurrent_sessions
            compute_capacity.desired_instances
          end
          
          def estimated_monthly_cost
            # Rough cost estimation based on instance type and capacity
            hourly_rate = case instance_type
                         when /stream\.standard\.small/ then 0.08
                         when /stream\.standard\.medium/ then 0.16
                         when /stream\.standard\.large/ then 0.31
                         when /stream\.compute\.large/ then 0.49
                         when /stream\.compute\.xlarge/ then 0.87
                         when /stream\.compute\.2xlarge/ then 1.74
                         when /stream\.compute\.4xlarge/ then 3.48
                         when /stream\.compute\.8xlarge/ then 6.96
                         when /stream\.memory\.large/ then 0.56
                         when /stream\.memory\.xlarge/ then 1.12
                         when /stream\.memory\.2xlarge/ then 2.24
                         when /stream\.memory\.4xlarge/ then 4.48
                         when /stream\.memory\.8xlarge/ then 8.96
                         when /stream\.graphics\.g4dn\.xlarge/ then 1.20
                         when /stream\.graphics\.g4dn\.2xlarge/ then 1.93
                         when /stream\.graphics\.g4dn\.4xlarge/ then 3.10
                         when /stream\.graphics\.g4dn\.8xlarge/ then 5.59
                         when /stream\.graphics\.g4dn\.12xlarge/ then 10.07
                         when /stream\.graphics\.g4dn\.16xlarge/ then 11.17
                         when /stream\.graphics-pro\.4xlarge/ then 3.78
                         when /stream\.graphics-pro\.8xlarge/ then 7.56
                         when /stream\.graphics-pro\.16xlarge/ then 15.12
                         else 0.16  # Default to medium
                         end
            
            if always_on?
              # Always-on fleets run 24/7
              hourly_rate * 730 * compute_capacity.desired_instances
            else
              # On-demand fleets - estimate 8 hours/day, 22 days/month
              hourly_rate * 8 * 22 * compute_capacity.desired_instances
            end
          end
        end
        
        # Compute capacity configuration
        class ComputeCapacityType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :desired_instances, Resources::Types::Integer.constrained(
            gteq: 1
          )
          
          # Computed based on fleet type
          def min_instances
            desired_instances  # AppStream manages scaling
          end
          
          def max_instances
            desired_instances  # AppStream manages scaling
          end
        end
        
        # VPC configuration
        class VpcConfigType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :subnet_ids, Resources::Types::Array.of(
            Resources::Types::String
          ).constrained(min_size: 1)
          
          attribute :security_group_ids, Resources::Types::Array.of(
            Resources::Types::String
          ).constrained(min_size: 1).optional
          
          # Validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate subnet count for high availability
            if attrs[:subnet_ids] && attrs[:subnet_ids].length == 1
              # Warning: Single subnet reduces availability
              # This is allowed but not recommended
            end
            
            super(attrs)
          end
          
          def multi_az?
            subnet_ids.length > 1
          end
        end
        
        # Domain join configuration
        class DomainJoinInfoType < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :directory_name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z0-9.-]+\z/
          )
          
          attribute :organizational_unit_distinguished_name, Resources::Types::String.optional
          
          # Validation for OU format
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:organizational_unit_distinguished_name]
              ou = attrs[:organizational_unit_distinguished_name]
              unless ou.match?(/\AOU=.+/)
                raise Dry::Struct::Error, "Organizational unit must be in format 'OU=...'"
              end
            end
            
            super(attrs)
          end
        end
      end
    end
  end
end