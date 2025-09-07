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
require 'dry-types'
require 'pangea/resources/types'

module Pangea
  module Components
    # Common types for component definitions
    module Types
      include Dry.Types()
      include Pangea::Resources::Types
      
      # Component-specific composite types
      
      # Multiple availability zones specification
      AvailabilityZones = Array.of(AwsAvailabilityZone).constrained(min_size: 1, max_size: 6)
      
      # CIDR blocks for subnet allocation
      SubnetCidrBlocks = Array.of(CidrBlock).constrained(min_size: 1, max_size: 10)
      
      # Security group rules collection
      SecurityGroupRules = Array.of(SecurityGroupRule).default([].freeze)
      
      # Component naming validation (alphanumeric, underscores, hyphens)
      ComponentName = String.constrained(
        format: /\A[a-zA-Z][a-zA-Z0-9_-]*\z/,
        max_size: 64
      )
      
      # VPC reference validation (either ResourceReference or Terraform reference string)
      VpcReference = String | Pangea::Resources::ResourceReference
      
      # Subnet references (array of ResourceReference objects or Terraform reference strings)
      SubnetReferences = Array.of(String | Pangea::Resources::ResourceReference)
      
      # Security group references
      SecurityGroupReferences = Array.of(String | Pangea::Resources::ResourceReference)
      
      # Route table references  
      RouteTableReferences = Array.of(String | Pangea::Resources::ResourceReference)
      
      # Internet gateway reference
      InternetGatewayReference = String | Pangea::Resources::ResourceReference
      
      # NAT gateway reference
      NatGatewayReference = String | Pangea::Resources::ResourceReference
      
      # Component feature flags
      ComponentFeatureFlags = Hash.schema(
        enable_flow_logs?: Bool.default(true),
        enable_dns_hostnames?: Bool.default(true),
        enable_dns_support?: Bool.default(true),
        create_nat_gateway?: Bool.default(true),
        create_internet_gateway?: Bool.default(true),
        enable_monitoring?: Bool.default(true)
      ).default({}.freeze)
      
      # High availability configuration
      HighAvailabilityConfig = Hash.schema(
        multi_az: Bool.default(true),
        min_availability_zones: Integer.default(2).constrained(gteq: 1, lteq: 6),
        distribute_evenly: Bool.default(true)
      ).default({}.freeze)
      
      # Security configuration for components
      SecurityConfig = Hash.schema(
        enable_flow_logs?: Bool.default(true),
        flow_log_destination?: String.default('cloud-watch-logs').enum('cloud-watch-logs', 's3'),
        restrict_default_sg?: Bool.default(true),
        enable_nacl_logging?: Bool.default(false),
        encryption_at_rest?: Bool.default(true),
        encryption_in_transit?: Bool.default(true)
      ).default({}.freeze)
      
      # Cost optimization configuration
      CostConfig = Hash.schema(
        use_spot_instances?: Bool.default(false),
        enable_savings_plans?: Bool.default(false),
        lifecycle_policies?: Bool.default(true),
        right_sizing?: Bool.default(true)
      ).default({}.freeze)
      
      # Monitoring and alerting configuration
      MonitoringConfig = Hash.schema(
        enable_cloudwatch?: Bool.default(true),
        enable_detailed_monitoring?: Bool.default(false),
        create_alarms?: Bool.default(true),
        log_retention_days?: Integer.default(30).constrained(gteq: 1, lteq: 3653),
        enable_xray?: Bool.default(false)
      ).default({}.freeze)
      
      # Network topology patterns
      NetworkTopology = String.enum(
        'single-tier',     # All resources in public subnets
        'two-tier',        # Public and private subnets
        'three-tier',      # Public, private, and database subnets
        'multi-tier'       # Custom multi-tier configuration
      )
      
      # Component deployment patterns
      DeploymentPattern = String.enum(
        'development',     # Single AZ, minimal redundancy
        'staging',         # Multi-AZ, moderate redundancy
        'production',      # Multi-AZ, high redundancy
        'disaster-recovery' # Cross-region, maximum redundancy
      )
      
      # Load balancing configuration
      LoadBalancingConfig = Hash.schema(
        type: LoadBalancerType,
        scheme: String.default('internet-facing').enum('internet-facing', 'internal'),
        enable_deletion_protection?: Bool.default(false),
        enable_cross_zone?: Bool.default(true),
        idle_timeout?: Integer.default(60).constrained(gteq: 1, lteq: 4000)
      ).default({}.freeze)
      
      # Auto scaling configuration
      AutoScalingConfig = Hash.schema(
        min_size: Integer.default(1).constrained(gteq: 0),
        max_size: Integer.default(3).constrained(gteq: 1),
        desired_capacity?: Integer.optional,
        target_group_arns?: Array.of(String).default([].freeze),
        health_check_type?: String.default('EC2').enum('EC2', 'ELB'),
        health_check_grace_period?: Integer.default(300).constrained(gteq: 0)
      ).default({}.freeze)
      
      # Database configuration
      DatabaseConfig = Hash.schema(
        engine: RdsEngine,
        engine_version?: String.optional,
        instance_class: RdsInstanceClass,
        allocated_storage?: Integer.default(20).constrained(gteq: 20),
        multi_az?: Bool.default(false),
        backup_retention_period?: Integer.default(7).constrained(gteq: 0, lteq: 35),
        enable_encryption?: Bool.default(true)
      )
      
      # Port configuration for security groups
      PortConfig = Hash.schema(
        http: Port.default(80),
        https: Port.default(443),
        ssh: Port.default(22),
        custom_ports?: Array.of(Port).default([].freeze)
      ).default({}.freeze)
      
      # Custom validation for subnet CIDR distribution
      SubnetCidrDistribution = Hash.schema(
        public_cidrs: SubnetCidrBlocks,
        private_cidrs?: SubnetCidrBlocks.optional,
        database_cidrs?: SubnetCidrBlocks.optional
      ).constructor { |value|
        # Validate that CIDR blocks don't overlap
        all_cidrs = []
        all_cidrs.concat(value[:public_cidrs] || [])
        all_cidrs.concat(value[:private_cidrs] || [])
        all_cidrs.concat(value[:database_cidrs] || [])
        
        # Basic overlap detection (simplified)
        if all_cidrs.uniq.length != all_cidrs.length
          raise Dry::Types::ConstraintError, "Duplicate CIDR blocks found in subnet distribution"
        end
        
        # Ensure public subnets exist
        if (value[:public_cidrs] || []).empty?
          raise Dry::Types::ConstraintError, "At least one public subnet CIDR is required"
        end
        
        value
      }
      
      # Tagging strategy configuration
      TaggingConfig = Hash.schema(
        environment?: String.optional,
        project?: String.optional,
        owner?: String.optional,
        cost_center?: String.optional,
        backup?: Bool.optional,
        auto_scaling?: Bool.optional,
        custom_tags?: AwsTags.default({}.freeze)
      ).default({}.freeze)
    end
  end
end