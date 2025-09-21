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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Load Balancer resources
      class LoadBalancerAttributes < Dry::Struct
        # Load balancer name (optional, AWS will generate if not provided)
        attribute :name, Resources::Types::String.optional

        # Load balancer type: "application", "network", or "gateway"
        attribute :load_balancer_type, Resources::Types::String.default("application").enum("application", "network", "gateway")

        # Internal load balancer (false = internet-facing, true = internal)
        attribute :internal, Resources::Types::Bool.default(false)

        # Subnet IDs where the load balancer will be provisioned
        attribute :subnet_ids, Resources::Types::Array.of(Types::String).constrained(min_size: 2)

        # Security groups (ALB only) - array of security group IDs
        attribute :security_groups, Resources::Types::Array.of(Types::String).default([].freeze)

        # IP address type: "ipv4" or "dualstack"
        attribute :ip_address_type, Resources::Types::String.optional.enum("ipv4", "dualstack")

        # Enable deletion protection
        attribute :enable_deletion_protection, Resources::Types::Bool.default(false)

        # Enable cross-zone load balancing (NLB only)
        attribute :enable_cross_zone_load_balancing, Resources::Types::Bool.optional

        # Access logs configuration
        attribute :access_logs, Resources::Types::Hash.schema(
          enabled: Types::Bool,
          bucket: Types::String,
          prefix?: Types::String.optional
        ).optional

        # Tags to apply to the load balancer
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation for type-specific attributes
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate security groups only for ALB
          if attrs.security_groups.any? && attrs.load_balancer_type != "application"
            raise Dry::Struct::Error, "security_groups can only be specified for application load balancers"
          end

          # Validate cross-zone load balancing only for NLB
          if !attrs.enable_cross_zone_load_balancing.nil? && attrs.load_balancer_type != "network"
            raise Dry::Struct::Error, "enable_cross_zone_load_balancing can only be specified for network load balancers"
          end

          attrs
        end
      end
    end
      end
    end
  end
end