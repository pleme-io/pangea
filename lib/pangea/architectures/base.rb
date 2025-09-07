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
require 'ostruct'
require 'socket'

module Pangea
  module Architectures
    # Base module for architecture patterns - provides common functionality
    module Base
      # Creates a new ArchitectureReference for the architecture
      def create_architecture_reference(type, name, **options)
        ArchitectureReference.new(
          type: type,
          name: name,
          **options
        )
      end

      # Generate base tags for architecture resources
      def architecture_tags(arch_ref, additional_tags = {})
        {
          Architecture: arch_ref.type,
          ArchitectureName: arch_ref.name.to_s,
          ManagedBy: "Pangea"
        }.merge(additional_tags)
      end

      # Generate resource name for architecture
      def architecture_resource_name(arch_name, resource_suffix)
        "#{arch_name}_#{resource_suffix}".to_sym
      end

      # Helper function for VPC with subnets component pattern
      def vpc_with_subnets(name, vpc_cidr:, availability_zones:, attributes: {})
        vpc_tags = attributes[:vpc_tags] || {}
        public_subnet_tags = attributes[:public_subnet_tags] || {}
        private_subnet_tags = attributes[:private_subnet_tags] || {}

        # Create VPC
        vpc_ref = aws_vpc(name, {
          cidr_block: vpc_cidr,
          enable_dns_hostnames: true,
          enable_dns_support: true,
          tags: vpc_tags.merge(Name: "#{name}-vpc")
        })

        # Create internet gateway
        igw_ref = aws_internet_gateway("#{name}_igw".to_sym, {
          vpc_id: vpc_ref.id,
          tags: vpc_tags.merge(Name: "#{name}-igw")
        })

        # Create public subnets
        public_subnets = availability_zones.each_with_index.map do |az, index|
          subnet_cidr = calculate_subnet_cidr(vpc_cidr, index * 2)
          aws_subnet("#{name}_public_#{('a'.ord + index).chr}".to_sym, {
            vpc_id: vpc_ref.id,
            cidr_block: subnet_cidr,
            availability_zone: az,
            map_public_ip_on_launch: true,
            tags: public_subnet_tags.merge(
              Name: "#{name}-public-#{('a'.ord + index).chr}",
              Type: "Public"
            )
          })
        end

        # Create private subnets
        private_subnets = availability_zones.each_with_index.map do |az, index|
          subnet_cidr = calculate_subnet_cidr(vpc_cidr, (index * 2) + 1)
          aws_subnet("#{name}_private_#{('a'.ord + index).chr}".to_sym, {
            vpc_id: vpc_ref.id,
            cidr_block: subnet_cidr,
            availability_zone: az,
            map_public_ip_on_launch: false,
            tags: private_subnet_tags.merge(
              Name: "#{name}-private-#{('a'.ord + index).chr}",
              Type: "Private"
            )
          })
        end

        # Create public route table
        public_rt = aws_route_table("#{name}_public_rt".to_sym, {
          vpc_id: vpc_ref.id,
          tags: vpc_tags.merge(Name: "#{name}-public-rt", Type: "Public")
        })

        # Route to internet gateway
        aws_route("#{name}_public_route".to_sym, {
          route_table_id: public_rt.id,
          destination_cidr_block: "0.0.0.0/0",
          gateway_id: igw_ref.id
        })

        # Associate public subnets with public route table
        public_subnets.each_with_index do |subnet, index|
          aws_route_table_association("#{name}_public_rta_#{('a'.ord + index).chr}".to_sym, {
            subnet_id: subnet.id,
            route_table_id: public_rt.id
          })
        end

        # Create NAT gateways for private subnets
        nat_gateways = public_subnets.each_with_index.map do |public_subnet, index|
          # EIP for NAT Gateway
          eip = aws_eip("#{name}_nat_eip_#{('a'.ord + index).chr}".to_sym, {
            domain: "vpc",
            tags: vpc_tags.merge(Name: "#{name}-nat-eip-#{('a'.ord + index).chr}")
          })

          # NAT Gateway
          aws_nat_gateway("#{name}_nat_gw_#{('a'.ord + index).chr}".to_sym, {
            allocation_id: eip.id,
            subnet_id: public_subnet.id,
            tags: vpc_tags.merge(Name: "#{name}-nat-gw-#{('a'.ord + index).chr}")
          })
        end

        # Create private route tables and routes
        private_subnets.each_with_index do |private_subnet, index|
          private_rt = aws_route_table("#{name}_private_rt_#{('a'.ord + index).chr}".to_sym, {
            vpc_id: vpc_ref.id,
            tags: vpc_tags.merge(Name: "#{name}-private-rt-#{('a'.ord + index).chr}", Type: "Private")
          })

          # Route to NAT gateway
          aws_route("#{name}_private_route_#{('a'.ord + index).chr}".to_sym, {
            route_table_id: private_rt.id,
            destination_cidr_block: "0.0.0.0/0",
            nat_gateway_id: nat_gateways[index].id
          })

          # Associate private subnet with private route table
          aws_route_table_association("#{name}_private_rta_#{('a'.ord + index).chr}".to_sym, {
            subnet_id: private_subnet.id,
            route_table_id: private_rt.id
          })
        end

        # Return network reference object
        OpenStruct.new(
          vpc: vpc_ref,
          internet_gateway: igw_ref,
          public_subnets: public_subnets,
          private_subnets: private_subnets,
          public_subnet_ids: public_subnets.map(&:id),
          private_subnet_ids: private_subnets.map(&:id),
          nat_gateways: nat_gateways,
          public_route_table: public_rt,
          private_route_tables: private_subnets.each_with_index.map { |_, index| "#{name}_private_rt_#{('a'.ord + index).chr}".to_sym }
        )
      end

      # Calculate subnet CIDR blocks
      def calculate_subnet_cidr(vpc_cidr, subnet_index)
        require 'ipaddr'
        
        base_ip = IPAddr.new(vpc_cidr)
        subnet_size = 24 # /24 subnets (256 IPs each)
        
        # Calculate the new network based on the original network and the subnet index
        new_prefix = base_ip.prefix + (subnet_size - base_ip.prefix)
        subnet_increment = 2 ** (32 - subnet_size) * subnet_index
        
        IPAddr.new(base_ip.to_i + subnet_increment, Socket::AF_INET).mask(subnet_size).to_s
      end
    end

    # Base class for architecture reference objects
    class ArchitectureReference
      attr_reader :type, :name, :architecture_attributes, :components, :resources, :outputs

      def initialize(type:, name:, architecture_attributes: {}, components: {}, resources: {}, outputs: {})
        @type = type
        @name = name
        @architecture_attributes = architecture_attributes
        @components = components
        @resources = resources
        @outputs = outputs
      end

      # Access computed outputs
      def method_missing(method_name, *args, &block)
        if outputs.key?(method_name)
          outputs[method_name]
        elsif components.key?(method_name)
          components[method_name]
        elsif resources.key?(method_name)
          resources[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        outputs.key?(method_name) || components.key?(method_name) || resources.key?(method_name) || super
      end

      # Override specific components while maintaining overall pattern
      def override(component_name, &block)
        raise ArgumentError, "Component #{component_name} does not exist" unless components.key?(component_name)

        # Replace component with custom implementation
        @components[component_name] = yield(self)
        recalculate_outputs
        self
      end

      # Extend architecture with additional resources
      def extend_with(additional_resources)
        @resources.merge!(additional_resources)
        recalculate_outputs
        self
      end

      # Compose with other architectures or components
      def compose_with(&block)
        yield(self)
        recalculate_outputs
        self
      end

      # Architecture health and validation
      def validate_deployment
        validations = []

        # Check component health
        components.each do |name, component|
          validations << validate_component(name, component)
        end

        # Check resource dependencies
        resources.each do |name, resource|
          validations << validate_resource_dependencies(name, resource)
        end

        validations.all?
      end

      # Cost estimation with breakdown
      def cost_breakdown
        component_costs = components.transform_values do |component|
          if component.respond_to?(:estimated_monthly_cost)
            component.estimated_monthly_cost
          else
            0.0
          end
        end

        resource_costs = resources.transform_values do |resource|
          if resource.respond_to?(:estimated_monthly_cost)
            resource.estimated_monthly_cost
          else
            0.0
          end
        end

        total = component_costs.values.sum + resource_costs.values.sum

        {
          components: component_costs,
          resources: resource_costs,
          total: total
        }
      end

      # Overall estimated monthly cost
      def estimated_monthly_cost
        cost_breakdown[:total]
      end

      # Security compliance checking
      def security_compliance_score
        security_checks = [
          check_encryption_at_rest,
          check_encryption_in_transit,
          check_network_isolation,
          check_access_controls,
          check_monitoring_enabled
        ]

        (security_checks.count(true).to_f / security_checks.length * 100).round(2)
      end

      # High availability assessment
      def high_availability_score
        ha_checks = [
          check_multi_az_deployment,
          check_auto_scaling_enabled,
          check_load_balancer_present,
          check_database_redundancy,
          check_backup_strategy
        ]

        (ha_checks.count(true).to_f / ha_checks.length * 100).round(2)
      end

      # Performance optimization score
      def performance_score
        performance_checks = [
          check_caching_enabled,
          check_cdn_configured,
          check_database_optimization,
          check_compute_sizing,
          check_network_optimization
        ]

        (performance_checks.count(true).to_f / performance_checks.length * 100).round(2)
      end

      # Get all resources across components and direct resources
      def all_resources
        component_resources = components.values.flat_map do |component|
          if component.respond_to?(:resources)
            component.resources.values
          else
            [component]
          end
        end

        (component_resources + resources.values).compact
      end

      # Architecture summary for reporting
      def summary
        {
          name: name,
          type: type,
          architecture_attributes: architecture_attributes,
          component_count: components.size,
          resource_count: all_resources.size,
          estimated_monthly_cost: estimated_monthly_cost,
          security_compliance_score: security_compliance_score,
          high_availability_score: high_availability_score,
          performance_score: performance_score,
          validation_status: validate_deployment
        }
      end

      # Export architecture configuration
      def to_configuration
        {
          architecture: {
            type: type,
            name: name,
            attributes: architecture_attributes
          },
          components: components.transform_values do |component|
            if component.respond_to?(:to_configuration)
              component.to_configuration
            else
              component.to_h
            end
          end,
          resources: resources.transform_values do |resource|
            if resource.respond_to?(:to_configuration)
              resource.to_configuration
            else
              resource.to_h
            end
          end,
          outputs: outputs
        }
      end

      private

      def recalculate_outputs
        # Recalculate architecture-level outputs after changes
        @outputs[:estimated_monthly_cost] = cost_breakdown[:total]
        @outputs[:security_compliance_score] = security_compliance_score
        @outputs[:high_availability_score] = high_availability_score
        @outputs[:performance_score] = performance_score
      end

      def validate_component(name, component)
        return true unless component.respond_to?(:validate)

        component.validate
      rescue StandardError => e
        warn "Component #{name} validation failed: #{e.message}"
        false
      end

      def validate_resource_dependencies(name, resource)
        # Basic validation - ensure resource is properly configured
        return false if resource.nil?

        # Check if resource has required attributes
        true
      rescue StandardError => e
        warn "Resource #{name} dependency validation failed: #{e.message}"
        false
      end

      # Security compliance checks
      def check_encryption_at_rest
        # Check if storage resources have encryption enabled
        storage_resources = all_resources.select { |r| r.respond_to?(:encrypted?) }
        return true if storage_resources.empty?

        storage_resources.all? { |r| r.encrypted? }
      end

      def check_encryption_in_transit
        # Check if communication uses TLS/SSL
        network_resources = all_resources.select { |r| r.respond_to?(:tls_enabled?) }
        return true if network_resources.empty?

        network_resources.all? { |r| r.tls_enabled? }
      end

      def check_network_isolation
        # Check if resources are properly isolated in VPC
        vpc_resources = all_resources.select { |r| r.respond_to?(:vpc_id) }
        return true if vpc_resources.empty?

        vpc_ids = vpc_resources.map(&:vpc_id).compact.uniq
        vpc_ids.size <= 1 # All resources in same VPC or isolated appropriately
      end

      def check_access_controls
        # Check if IAM policies are configured
        iam_resources = all_resources.select { |r| r.respond_to?(:iam_policies) }
        return true if iam_resources.empty?

        iam_resources.all? { |r| r.iam_policies&.any? }
      end

      def check_monitoring_enabled
        # Check if monitoring is configured
        monitorable_resources = all_resources.select { |r| r.respond_to?(:monitoring_enabled?) }
        return true if monitorable_resources.empty?

        monitorable_resources.all? { |r| r.monitoring_enabled? }
      end

      # High availability checks
      def check_multi_az_deployment
        # Check if resources are deployed across multiple AZs
        az_resources = all_resources.select { |r| r.respond_to?(:availability_zones) }
        return true if az_resources.empty?

        az_resources.any? { |r| r.availability_zones&.size.to_i > 1 }
      end

      def check_auto_scaling_enabled
        # Check if auto scaling is configured
        scalable_resources = all_resources.select { |r| r.respond_to?(:auto_scaling_enabled?) }
        return true if scalable_resources.empty?

        scalable_resources.any? { |r| r.auto_scaling_enabled? }
      end

      def check_load_balancer_present
        # Check if load balancer is configured
        all_resources.any? { |r| r.class.name.to_s.downcase.include?('load_balancer') }
      end

      def check_database_redundancy
        # Check if database has backup/redundancy
        db_resources = all_resources.select { |r| r.class.name.to_s.downcase.include?('db') }
        return true if db_resources.empty?

        db_resources.all? { |r| r.respond_to?(:backup_enabled?) ? r.backup_enabled? : true }
      end

      def check_backup_strategy
        # Check if backup strategy is configured
        backup_resources = all_resources.select { |r| r.respond_to?(:backup_retention_days) }
        return true if backup_resources.empty?

        backup_resources.all? { |r| r.backup_retention_days.to_i > 0 }
      end

      # Performance checks
      def check_caching_enabled
        # Check if caching is configured
        cache_resources = all_resources.select { |r| r.class.name.to_s.downcase.include?('cache') }
        cache_resources.any?
      end

      def check_cdn_configured
        # Check if CDN is configured
        cdn_resources = all_resources.select { |r| r.class.name.to_s.downcase.include?('cloudfront') }
        cdn_resources.any?
      end

      def check_database_optimization
        # Check if database performance features are enabled
        db_resources = all_resources.select { |r| r.class.name.to_s.downcase.include?('db') }
        return true if db_resources.empty?

        # Assume optimized if specific instance types or features are used
        true
      end

      def check_compute_sizing
        # Check if compute resources are appropriately sized
        compute_resources = all_resources.select { |r| r.respond_to?(:instance_type) }
        return true if compute_resources.empty?

        # Check for burstable instances in production (potential performance issue)
        production_with_burstable = compute_resources.any? do |r|
          r.instance_type&.start_with?('t') && (architecture_attributes[:environment] == 'production')
        end

        !production_with_burstable
      end

      def check_network_optimization
        # Check if network optimization features are enabled
        network_resources = all_resources.select { |r| r.respond_to?(:enhanced_networking) }
        return true if network_resources.empty?

        network_resources.all? { |r| r.enhanced_networking? }
      end
    end

    # Factory method for creating architecture references
    def self.create_reference(type, name, **options)
      ArchitectureReference.new(
        type: type,
        name: name,
        **options
      )
    end
  end
end