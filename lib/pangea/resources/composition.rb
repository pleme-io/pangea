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


require 'pangea/resources/reference'
require 'ipaddr'

module Pangea
  module Resources
    # Resource composition helpers for common infrastructure patterns
    module Composition
      include AWS
      # Create a VPC with public and private subnets across multiple AZs
      #
      # @param name_prefix [Symbol] Prefix for resource names
      # @param vpc_cidr [String] CIDR block for VPC
      # @param availability_zones [Array<String>] AZs to create subnets in
      # @param attributes [Hash] Additional attributes and customization
      # @return [CompositeVpcReference] Composite reference with all created resources
      def vpc_with_subnets(name_prefix, vpc_cidr:, availability_zones:, public_subnet_cidrs: nil, private_subnet_cidrs: nil, attributes: {})
        results = CompositeVpcReference.new(name_prefix)
        
        # Create VPC
        results.vpc = aws_vpc(:"#{name_prefix}_vpc", {
          cidr_block: vpc_cidr,
          enable_dns_hostnames: true,
          enable_dns_support: true,
          tags: { Name: "#{name_prefix}-vpc" }.merge(attributes[:vpc_tags] || {})
        })
        
        # Create Internet Gateway
        results.internet_gateway = aws_internet_gateway(:"#{name_prefix}_igw", {
          vpc_id: results.vpc.id,
          tags: { Name: "#{name_prefix}-igw" }.merge(attributes[:igw_tags] || {})
        })
        
        # Calculate subnet CIDR blocks or use provided ones
        vpc_cidr_parts = vpc_cidr.split('/')
        base_ip = vpc_cidr_parts[0]
        vpc_size = vpc_cidr_parts[1].to_i
        
        # Get custom CIDR blocks if provided
        public_cidrs = public_subnet_cidrs || []
        private_cidrs = private_subnet_cidrs || []
        
        # Validate availability zones
        raise ArgumentError, "At least one availability zone must be specified" if availability_zones.empty?
        
        # Calculate total subnets needed
        total_subnets = availability_zones.length * 2
        subnet_bits = Math.log2(total_subnets).ceil
        new_subnet_size = vpc_size + subnet_bits
        
        # Create public and private subnets in each AZ
        availability_zones.each_with_index do |az, index|
          # Public subnet
          public_cidr = public_cidrs[index] || calculate_subnet_cidr_v2(base_ip, vpc_size, new_subnet_size, index)
          public_subnet = aws_subnet(:"#{name_prefix}_public_subnet_#{index}", {
            vpc_id: results.vpc.id,
            cidr_block: public_cidr,
            availability_zone: az,
            map_public_ip_on_launch: true,
            tags: { 
              Name: "#{name_prefix}-public-#{index}",
              Type: "public"
            }.merge(attributes[:public_subnet_tags] || {})
          })
          results.public_subnets << public_subnet
          
          # Private subnet
          private_cidr = private_cidrs[index] || calculate_subnet_cidr_v2(base_ip, vpc_size, new_subnet_size, index + availability_zones.length)
          private_subnet = aws_subnet(:"#{name_prefix}_private_subnet_#{index}", {
            vpc_id: results.vpc.id,
            cidr_block: private_cidr,
            availability_zone: az,
            map_public_ip_on_launch: false,
            tags: { 
              Name: "#{name_prefix}-private-#{index}",
              Type: "private"
            }.merge(attributes[:private_subnet_tags] || {})
          })
          results.private_subnets << private_subnet
        end
        
        # Create NAT Gateways for private subnets (one per AZ)
        availability_zones.each_with_index do |az, index|
          # Create Elastic IP for NAT Gateway
          # Note: In real terraform we'd create an aws_eip resource, but for now we'll skip it
          nat_gateway = aws_nat_gateway(:"#{name_prefix}_nat_#{index}", {
            subnet_id: results.public_subnets[index].id,
            tags: { Name: "#{name_prefix}-nat-#{index}" }.merge(attributes[:nat_tags] || {})
          })
          results.nat_gateways << nat_gateway
        end
        
        # Create route table for public subnets
        results.public_route_table = aws_route_table(:"#{name_prefix}_public_rt", {
          vpc_id: results.vpc.id,
          routes: [
            {
              cidr_block: "0.0.0.0/0",
              gateway_id: results.internet_gateway.id
            }
          ],
          tags: { Name: "#{name_prefix}-public-rt" }.merge(attributes[:route_table_tags] || {})
        })
        
        # Create route tables for private subnets (one per AZ for HA)
        availability_zones.each_with_index do |az, index|
          private_route_table = aws_route_table(:"#{name_prefix}_private_rt_#{index}", {
            vpc_id: results.vpc.id,
            routes: [
              {
                cidr_block: "0.0.0.0/0",
                nat_gateway_id: results.nat_gateways[index].id
              }
            ],
            tags: { Name: "#{name_prefix}-private-rt-#{index}" }.merge(attributes[:route_table_tags] || {})
          })
          results.private_route_tables << private_route_table
        end
        
        results
      end
      
      # Create a web server with its required networking components
      #
      # @param name [Symbol] Server name
      # @param subnet_ref [ResourceReference] Subnet to place the instance in
      # @param attributes [Hash] Instance attributes and customization
      # @return [CompositeWebServerReference] Reference with instance and security group
      def web_server(name, subnet_ref:, attributes: {})
        results = CompositeWebServerReference.new(name)
        
        # Create security group for web server
        results.security_group = aws_security_group(:"#{name}_sg", {
          name_prefix: "#{name}-sg",
          vpc_id: subnet_ref.vpc_id,
          ingress_rules: [
            {
              from_port: 80,
              to_port: 80,
              protocol: "tcp",
              cidr_blocks: ["0.0.0.0/0"],
              description: "HTTP"
            },
            {
              from_port: 443,
              to_port: 443,
              protocol: "tcp", 
              cidr_blocks: ["0.0.0.0/0"],
              description: "HTTPS"
            },
            {
              from_port: 22,
              to_port: 22,
              protocol: "tcp",
              cidr_blocks: [subnet_ref.computed_attributes.cidr_block],
              description: "SSH from subnet"
            }
          ],
          tags: { Name: "#{name}-security-group" }.merge(attributes[:sg_tags] || {})
        })
        
        # Create EC2 instance
        results.instance = aws_instance(name, {
          ami: attributes[:ami] || "ami-0c55b159cbfafe1f0",
          instance_type: attributes[:instance_type] || "t3.micro",
          subnet_id: subnet_ref.id,
          vpc_security_group_ids: [results.security_group.id],
          key_name: attributes[:key_name],
          user_data: attributes[:user_data] || default_web_server_user_data,
          tags: { 
            Name: "#{name}-web-server",
            Type: "web" 
          }.merge(attributes[:instance_tags] || {})
        })
        
        results
      end
      
      # Create an auto-scaling web tier with load balancer integration
      #
      # @param name [Symbol] Base name for resources
      # @param vpc_ref [ResourceReference] VPC reference
      # @param subnet_refs [Array<ResourceReference>] Subnet references for instances
      # @param load_balancer_ref [ResourceReference] Load balancer reference (optional)
      # @param attributes [Hash] Configuration attributes
      # @return [CompositeWebServerReference] Composite reference with all created resources
      def auto_scaling_web_tier(name, vpc_ref:, subnet_refs:, load_balancer_ref: nil, **attributes)
        results = CompositeWebServerReference.new(name)
        
        # Default attributes
        defaults = {
          instance_type: 't3.micro',
          min_instances: 1,
          max_instances: 10,
          desired_instances: 2,
          ami_id: 'ami-0c55b159cbfafe1f0',
          key_name: nil,
          user_data: nil,
          health_check_path: '/',
          tags: {}
        }
        
        config = defaults.merge(attributes)
        
        # Create security group for instances
        results.security_group = aws_security_group(:"#{name}_sg", {
          name_prefix: "#{name}-sg-",
          vpc_id: vpc_ref.id,
          description: "Security group for #{name} auto scaling group",
          ingress_rules: [
            {
              from_port: 80,
              to_port: 80,
              protocol: "tcp",
              cidr_blocks: ["0.0.0.0/0"],
              description: "HTTP"
            },
            {
              from_port: 443,
              to_port: 443,
              protocol: "tcp",
              cidr_blocks: ["0.0.0.0/0"],
              description: "HTTPS"
            }
          ],
          egress_rules: [
            {
              from_port: 0,
              to_port: 0,
              protocol: "-1",
              cidr_blocks: ["0.0.0.0/0"],
              description: "All outbound traffic"
            }
          ],
          tags: { Name: "#{name}-security-group" }.merge(config[:tags])
        })
        
        # Create launch template
        results.launch_template = aws_launch_template(:"#{name}_launch_template", {
          name_prefix: "#{name}-lt-",
          image_id: config[:ami_id],
          instance_type: config[:instance_type],
          key_name: config[:key_name],
          vpc_security_group_ids: [results.security_group.id],
          user_data: config[:user_data],
          tags: { Name: "#{name}-launch-template" }.merge(config[:tags])
        })
        
        # Create target group
        results.target_group = aws_lb_target_group(:"#{name}_target_group", {
          port: 80,
          protocol: "HTTP",
          vpc_id: vpc_ref.id,
          target_type: "instance",
          health_check: {
            enabled: true,
            healthy_threshold: 2,
            unhealthy_threshold: 2,
            timeout: 5,
            interval: 30,
            path: config[:health_check_path],
            matcher: "200"
          },
          tags: { Name: "#{name}-target-group" }.merge(config[:tags])
        })
        
        # Create auto scaling group
        results.auto_scaling_group = aws_autoscaling_group(:"#{name}_asg", {
          min_size: config[:min_instances],
          max_size: config[:max_instances],
          desired_capacity: config[:desired_instances],
          vpc_zone_identifier: subnet_refs.map(&:id),
          launch_template: {
            id: results.launch_template.id,
            version: "$Latest"
          },
          health_check_type: "ELB",
          health_check_grace_period: 300,
          tags: [
            {
              key: "Name",
              value: "#{name}-instance",
              propagate_at_launch: true
            }
          ].concat(config[:tags].map { |k, v| { key: k.to_s, value: v, propagate_at_launch: true } })
        })
        
        # Attach ASG to target group
        results.asg_attachment = aws_autoscaling_attachment(:"#{name}_asg_attachment", {
          autoscaling_group_name: results.auto_scaling_group.ref(:name),
          lb_target_group_arn: results.target_group.ref(:arn)
        })
        
        # Create scaling policies
        results.scale_up_policy = aws_autoscaling_policy(:"#{name}_scale_up", {
          autoscaling_group_name: results.auto_scaling_group.ref(:name),
          adjustment_type: "ChangeInCapacity",
          scaling_adjustment: 1,
          cooldown: 300
        })
        
        results.scale_down_policy = aws_autoscaling_policy(:"#{name}_scale_down", {
          autoscaling_group_name: results.auto_scaling_group.ref(:name),
          adjustment_type: "ChangeInCapacity",
          scaling_adjustment: -1,
          cooldown: 300
        })
        
        # Create CloudWatch alarms for scaling
        results.cpu_high_alarm = aws_cloudwatch_metric_alarm(:"#{name}_cpu_high", {
          alarm_description: "Trigger scale up when CPU exceeds 70%",
          comparison_operator: "GreaterThanThreshold",
          evaluation_periods: 2,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 70,
          alarm_actions: [results.scale_up_policy.ref(:arn)],
          dimensions: {
            AutoScalingGroupName: results.auto_scaling_group.ref(:name)
          }
        })
        
        results.cpu_low_alarm = aws_cloudwatch_metric_alarm(:"#{name}_cpu_low", {
          alarm_description: "Trigger scale down when CPU drops below 30%",
          comparison_operator: "LessThanThreshold",
          evaluation_periods: 2,
          metric_name: "CPUUtilization",
          namespace: "AWS/EC2",
          period: 300,
          statistic: "Average",
          threshold: 30,
          alarm_actions: [results.scale_down_policy.ref(:arn)],
          dimensions: {
            AutoScalingGroupName: results.auto_scaling_group.ref(:name)
          }
        })
        
        results
      end
      
      private
      
      # Helper to base64 encode strings
      def base64encode(str)
        require 'base64'
        Base64.strict_encode64(str)
      end
      
      # Calculate subnet CIDR for a given index
      def calculate_subnet_cidr(base_ip, vpc_size, subnet_index)
        ip_parts = base_ip.split('.').map(&:to_i)
        
        # Assume /24 subnets within larger VPC
        subnet_increment = subnet_index
        
        # Adjust third octet
        ip_parts[2] += subnet_increment
        
        "#{ip_parts.join('.')}/24"
      end
      
      # Better subnet CIDR calculation that works with any VPC size
      def calculate_subnet_cidr_v2(base_ip, vpc_size, subnet_size, index)
        require 'ipaddr'
        vpc_network = IPAddr.new("#{base_ip}/#{vpc_size}")
        
        # Calculate the increment based on subnet size
        subnet_hosts = 2 ** (32 - subnet_size)
        offset = index * subnet_hosts
        
        # Create the subnet
        subnet_ip = vpc_network.to_i + offset
        subnet_network = IPAddr.new(subnet_ip, Socket::AF_INET)
        
        "#{subnet_network}/#{subnet_size}"
      end
      
      # Default user data for web servers
      def default_web_server_user_data
        base64encode(<<~USERDATA)
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          echo "<h1>Hello from Pangea!</h1>" > /var/www/html/index.html
          echo "<p>This server was created with type-safe resource composition.</p>" >> /var/www/html/index.html
        USERDATA
      end
    end
    
    # Composite reference for VPC with subnets
    class CompositeVpcReference
      attr_accessor :vpc, :internet_gateway, :public_route_table
      attr_reader :name_prefix, :public_subnets, :private_subnets, :nat_gateways, :private_route_tables
      
      def initialize(name_prefix)
        @name_prefix = name_prefix
        @public_subnets = []
        @private_subnets = []
        @nat_gateways = []
        @private_route_tables = []
      end
      
      # Helper methods for accessing subnet collections
      def public_subnet_ids
        @public_subnets.map(&:id)
      end
      
      def private_subnet_ids
        @private_subnets.map(&:id)
      end
      
      def all_subnet_ids
        public_subnet_ids + private_subnet_ids
      end
      
      # Access subnets by AZ
      def public_subnet_in_az(az)
        @public_subnets.find { |subnet| subnet.resource_attributes[:availability_zone] == az }
      end
      
      def private_subnet_in_az(az)
        @private_subnets.find { |subnet| subnet.resource_attributes[:availability_zone] == az }
      end
      
      # Get all resources for tracking
      def all_resources
        resources = []
        resources << @vpc if @vpc
        resources << @internet_gateway if @internet_gateway
        resources << @public_route_table if @public_route_table
        resources.concat(@public_subnets)
        resources.concat(@private_subnets)
        resources.concat(@nat_gateways)
        resources.concat(@private_route_tables)
        resources
      end
      
      # Resource counts
      def availability_zone_count
        @public_subnets.length
      end
    end
    
    # Composite reference for web server resources
    class CompositeWebServerReference
      attr_accessor :instance, :security_group
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
      
      # Convenience accessors
      def public_ip
        @instance&.public_ip
      end
      
      def private_ip
        @instance&.private_ip
      end
      
      def instance_id
        @instance&.id
      end
      
      def security_group_id
        @security_group&.id
      end
    end
    
    # Composite reference for auto scaling web tier
    class CompositeWebServerReference
      attr_accessor :security_group, :launch_template, :auto_scaling_group, :target_group,
                    :asg_attachment, :scale_up_policy, :scale_down_policy, 
                    :cpu_high_alarm, :cpu_low_alarm
      attr_reader :name
      
      def initialize(name)
        @name = name
      end
      
      # Convenience methods
      def min_instances
        @auto_scaling_group&.resource_attributes[:min_size]
      end
      
      def max_instances
        @auto_scaling_group&.resource_attributes[:max_size]
      end
      
      def desired_instances
        @auto_scaling_group&.resource_attributes[:desired_capacity]
      end
      
      def instance_type
        @launch_template&.resource_attributes[:instance_type]
      end
      
      # Get all resources for tracking
      def all_resources
        resources = []
        resources << @security_group if @security_group
        resources << @launch_template if @launch_template
        resources << @auto_scaling_group if @auto_scaling_group
        resources << @target_group if @target_group
        resources << @asg_attachment if @asg_attachment
        resources << @scale_up_policy if @scale_up_policy
        resources << @scale_down_policy if @scale_down_policy
        resources << @cpu_high_alarm if @cpu_high_alarm
        resources << @cpu_low_alarm if @cpu_low_alarm
        resources
      end
    end
  end
end