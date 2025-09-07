# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Batch Compute Environment attributes with validation
        class BatchComputeEnvironmentAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :compute_environment_name, Resources::Types::String
          attribute :type, Resources::Types::String
          
          # Optional attributes
          attribute? :state, Resources::Types::String.optional.default("ENABLED")
          attribute? :service_role, Resources::Types::String.optional
          attribute? :compute_resources, Resources::Types::Hash.optional
          attribute? :tags, Resources::Types::Hash.optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate compute environment name
            if attrs[:compute_environment_name]
              validate_compute_environment_name(attrs[:compute_environment_name])
            end
            
            # Validate type
            if attrs[:type] && !%w[MANAGED UNMANAGED].include?(attrs[:type])
              raise Dry::Struct::Error, "Compute environment type must be 'MANAGED' or 'UNMANAGED'"
            end
            
            # Validate state
            if attrs[:state] && !%w[ENABLED DISABLED].include?(attrs[:state])
              raise Dry::Struct::Error, "Compute environment state must be 'ENABLED' or 'DISABLED'"
            end
            
            # Validate compute resources for MANAGED environments
            if attrs[:type] == "MANAGED" && attrs[:compute_resources]
              validate_compute_resources(attrs[:compute_resources])
            end
            
            # UNMANAGED environments should not have compute resources
            if attrs[:type] == "UNMANAGED" && attrs[:compute_resources]
              raise Dry::Struct::Error, "UNMANAGED compute environments cannot have compute_resources"
            end
            
            super(attrs)
          end
          
          def self.validate_compute_environment_name(name)
            # Name must be 1-128 characters
            if name.length < 1 || name.length > 128
              raise Dry::Struct::Error, "Compute environment name must be between 1 and 128 characters"
            end
            
            # Must contain only alphanumeric, hyphens, and underscores
            unless name.match?(/^[a-zA-Z0-9\-_]+$/)
              raise Dry::Struct::Error, "Compute environment name can only contain letters, numbers, hyphens, and underscores"
            end
            
            true
          end
          
          def self.validate_compute_resources(resources)
            unless resources.is_a?(Hash)
              raise Dry::Struct::Error, "Compute resources must be a hash"
            end
            
            # Validate compute resource type
            if resources[:type] && !%w[EC2 SPOT FARGATE FARGATE_SPOT].include?(resources[:type])
              raise Dry::Struct::Error, "Compute resource type must be one of: EC2, SPOT, FARGATE, FARGATE_SPOT"
            end
            
            # Validate allocation strategy
            if resources[:allocation_strategy]
              valid_strategies = case resources[:type]
              when "EC2", "SPOT"
                %w[BEST_FIT BEST_FIT_PROGRESSIVE SPOT_CAPACITY_OPTIMIZED]
              when "FARGATE", "FARGATE_SPOT"
                ["SPOT_CAPACITY_OPTIMIZED"]
              else
                []
              end
              
              unless valid_strategies.include?(resources[:allocation_strategy])
                raise Dry::Struct::Error, "Invalid allocation strategy '#{resources[:allocation_strategy]}' for type '#{resources[:type]}'"
              end
            end
            
            # Validate min/max/desired vCPUs
            if resources[:min_vcpus] && resources[:min_vcpus] < 0
              raise Dry::Struct::Error, "min_vcpus must be non-negative"
            end
            
            if resources[:max_vcpus] && resources[:max_vcpus] < 0
              raise Dry::Struct::Error, "max_vcpus must be non-negative"
            end
            
            if resources[:desired_vcpus] && resources[:desired_vcpus] < 0
              raise Dry::Struct::Error, "desired_vcpus must be non-negative"
            end
            
            if resources[:min_vcpus] && resources[:max_vcpus] && resources[:min_vcpus] > resources[:max_vcpus]
              raise Dry::Struct::Error, "min_vcpus cannot be greater than max_vcpus"
            end
            
            if resources[:desired_vcpus] && resources[:max_vcpus] && resources[:desired_vcpus] > resources[:max_vcpus]
              raise Dry::Struct::Error, "desired_vcpus cannot be greater than max_vcpus"
            end
            
            # Validate instance types for EC2/SPOT
            if %w[EC2 SPOT].include?(resources[:type]) && resources[:instance_types]
              validate_instance_types(resources[:instance_types])
            end
            
            # Validate Spot fleet configuration
            if resources[:type] == "SPOT" && resources[:spot_iam_fleet_request_role].nil?
              raise Dry::Struct::Error, "SPOT compute resources require spot_iam_fleet_request_role"
            end
            
            # Validate platform capabilities for Fargate
            if %w[FARGATE FARGATE_SPOT].include?(resources[:type])
              if resources[:platform_capabilities] && !resources[:platform_capabilities].include?("FARGATE")
                raise Dry::Struct::Error, "Fargate compute resources must include FARGATE platform capability"
              end
            end
            
            true
          end
          
          def self.validate_instance_types(instance_types)
            return true if instance_types == ["optimal"]
            
            unless instance_types.is_a?(Array) && instance_types.all? { |type| type.is_a?(String) }
              raise Dry::Struct::Error, "Instance types must be an array of strings"
            end
            
            # Basic EC2 instance type format validation
            instance_types.each do |type|
              unless type.match?(/^[a-z0-9]+\.[a-z0-9]+$/) || type == "optimal"
                raise Dry::Struct::Error, "Invalid instance type format: #{type}"
              end
            end
            
            true
          end
          
          # Computed properties
          def is_managed?
            type == "MANAGED"
          end
          
          def is_unmanaged?
            type == "UNMANAGED"
          end
          
          def is_enabled?
            state == "ENABLED"
          end
          
          def is_disabled?
            state == "DISABLED"
          end
          
          def supports_ec2?
            compute_resources && %w[EC2 SPOT].include?(compute_resources[:type])
          end
          
          def supports_fargate?
            compute_resources && %w[FARGATE FARGATE_SPOT].include?(compute_resources[:type])
          end
          
          def is_spot_based?
            compute_resources && %w[SPOT FARGATE_SPOT].include?(compute_resources[:type])
          end
          
          # Configuration templates
          def self.ec2_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "EC2",
                allocation_strategy: "BEST_FIT_PROGRESSIVE",
                min_vcpus: options[:min_vcpus] || 0,
                max_vcpus: options[:max_vcpus] || 100,
                desired_vcpus: options[:desired_vcpus] || 0,
                instance_types: options[:instance_types] || ["optimal"],
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                instance_role: options[:instance_role],
                tags: options[:tags] || {}
              }
            }
          end
          
          def self.spot_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "SPOT",
                allocation_strategy: "SPOT_CAPACITY_OPTIMIZED",
                min_vcpus: options[:min_vcpus] || 0,
                max_vcpus: options[:max_vcpus] || 100,
                desired_vcpus: options[:desired_vcpus] || 0,
                instance_types: options[:instance_types] || ["optimal"],
                spot_iam_fleet_request_role: options[:spot_iam_fleet_request_role],
                bid_percentage: options[:bid_percentage] || 50,
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                instance_role: options[:instance_role],
                tags: options[:tags] || {}
              }
            }
          end
          
          def self.fargate_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "FARGATE",
                max_vcpus: options[:max_vcpus] || 100,
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                platform_capabilities: ["FARGATE"],
                tags: options[:tags] || {}
              }
            }
          end
          
          def self.fargate_spot_managed_environment(name, vpc_config, options = {})
            {
              compute_environment_name: name,
              type: "MANAGED",
              state: "ENABLED",
              compute_resources: {
                type: "FARGATE_SPOT",
                max_vcpus: options[:max_vcpus] || 100,
                subnets: vpc_config[:subnets],
                security_group_ids: vpc_config[:security_group_ids],
                platform_capabilities: ["FARGATE"],
                tags: options[:tags] || {}
              }
            }
          end
          
          def self.unmanaged_environment(name, options = {})
            {
              compute_environment_name: name,
              type: "UNMANAGED",
              state: options[:state] || "ENABLED",
              service_role: options[:service_role],
              tags: options[:tags] || {}
            }
          end
          
          # Common instance type groups
          def self.compute_optimized_instances
            %w[c4.large c4.xlarge c4.2xlarge c4.4xlarge c4.8xlarge
               c5.large c5.xlarge c5.2xlarge c5.4xlarge c5.9xlarge c5.12xlarge c5.18xlarge c5.24xlarge
               c5n.large c5n.xlarge c5n.2xlarge c5n.4xlarge c5n.9xlarge c5n.18xlarge
               c6i.large c6i.xlarge c6i.2xlarge c6i.4xlarge c6i.8xlarge c6i.12xlarge c6i.16xlarge c6i.24xlarge c6i.32xlarge]
          end
          
          def self.memory_optimized_instances
            %w[r4.large r4.xlarge r4.2xlarge r4.4xlarge r4.8xlarge r4.16xlarge
               r5.large r5.xlarge r5.2xlarge r5.4xlarge r5.8xlarge r5.12xlarge r5.16xlarge r5.24xlarge
               r5a.large r5a.xlarge r5a.2xlarge r5a.4xlarge r5a.8xlarge r5a.12xlarge r5a.16xlarge r5a.24xlarge
               r6i.large r6i.xlarge r6i.2xlarge r6i.4xlarge r6i.8xlarge r6i.12xlarge r6i.16xlarge r6i.24xlarge r6i.32xlarge]
          end
          
          def self.general_purpose_instances
            %w[m4.large m4.xlarge m4.2xlarge m4.4xlarge m4.10xlarge m4.16xlarge
               m5.large m5.xlarge m5.2xlarge m5.4xlarge m5.8xlarge m5.12xlarge m5.16xlarge m5.24xlarge
               m5a.large m5a.xlarge m5a.2xlarge m5a.4xlarge m5a.8xlarge m5a.12xlarge m5a.16xlarge m5a.24xlarge
               m6i.large m6i.xlarge m6i.2xlarge m6i.4xlarge m6i.8xlarge m6i.12xlarge m6i.16xlarge m6i.24xlarge m6i.32xlarge]
          end
          
          def self.gpu_instances
            %w[p2.xlarge p2.8xlarge p2.16xlarge
               p3.2xlarge p3.8xlarge p3.16xlarge
               p3dn.24xlarge
               g3.4xlarge g3.8xlarge g3.16xlarge
               g4dn.xlarge g4dn.2xlarge g4dn.4xlarge g4dn.8xlarge g4dn.12xlarge g4dn.16xlarge]
          end
          
          # Validation helpers
          def self.validate_vpc_configuration(vpc_config)
            unless vpc_config.is_a?(Hash)
              raise Dry::Struct::Error, "VPC configuration must be a hash"
            end
            
            unless vpc_config[:subnets] && vpc_config[:subnets].is_a?(Array) && !vpc_config[:subnets].empty?
              raise Dry::Struct::Error, "VPC configuration must include non-empty subnets array"
            end
            
            unless vpc_config[:security_group_ids] && vpc_config[:security_group_ids].is_a?(Array) && !vpc_config[:security_group_ids].empty?
              raise Dry::Struct::Error, "VPC configuration must include non-empty security_group_ids array"
            end
            
            true
          end
        end
      end
    end
  end
end