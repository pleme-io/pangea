# frozen_string_literal: true

require 'spec_helper'
require 'terraform-synthesizer'

RSpec.describe 'Resource Composition Functions with Terraform Synthesizer' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe '#vpc_with_subnets' do
    let(:vpc_attributes) do
      {
        vpc_cidr: '10.0.0.0/16',
        availability_zones: ['us-east-1a', 'us-east-1b'],
        attributes: {
          vpc_tags: { Name: 'test-vpc', Environment: 'test' },
          public_subnet_tags: { Type: 'public' },
          private_subnet_tags: { Type: 'private' }
        }
      }
    end

    subject do
      result = nil
      attributes = vpc_attributes
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        result = vpc_with_subnets(:test_network, **attributes)
      end
      result
    end

    it 'returns a CompositeVpcReference' do
      expect(subject).to be_a(Pangea::Resources::CompositeVpcReference)
    end

    it 'creates VPC with correct attributes' do
      expect(subject.vpc.type).to eq('aws_vpc')
      expect(subject.vpc.name).to eq(:test_network_vpc)
      expect(subject.vpc.resource_attributes[:cidr_block]).to eq('10.0.0.0/16')
      expect(subject.vpc.resource_attributes[:tags][:Name]).to eq('test-vpc')
    end

    it 'creates public subnets in each AZ' do
      expect(subject.public_subnets.size).to eq(2)
      
      subject.public_subnets.each_with_index do |subnet, index|
        expect(subnet.type).to eq('aws_subnet')
        expect(subnet.name).to eq(:"test_network_public_subnet_#{index}")
        expect(subnet.resource_attributes[:vpc_id]).to eq(subject.vpc.ref(:id))
        expect(subnet.resource_attributes[:map_public_ip_on_launch]).to be true
        expect(subnet.resource_attributes[:tags][:Type]).to eq('public')
      end
    end

    it 'creates private subnets in each AZ' do
      expect(subject.private_subnets.size).to eq(2)
      
      subject.private_subnets.each_with_index do |subnet, index|
        expect(subnet.type).to eq('aws_subnet')
        expect(subnet.name).to eq(:"test_network_private_subnet_#{index}")
        expect(subnet.resource_attributes[:vpc_id]).to eq(subject.vpc.ref(:id))
        expect(subnet.resource_attributes[:map_public_ip_on_launch]).to be false
        expect(subnet.resource_attributes[:tags][:Type]).to eq('private')
      end
    end

    it 'calculates correct CIDR blocks for subnets' do
      # With /16 VPC and 4 subnets (2 public, 2 private), should get /18 subnets
      expected_cidrs = [
        '10.0.0.0/18',   # First public
        '10.0.64.0/18',  # Second public  
        '10.0.128.0/18', # First private
        '10.0.192.0/18'  # Second private
      ]

      actual_cidrs = (subject.public_subnets + subject.private_subnets)
                     .map { |subnet| subnet.resource_attributes[:cidr_block] }
      
      expect(actual_cidrs).to eq(expected_cidrs)
      
      # Verify terraform synthesis
      tf_json = synthesizer.synthesis
      expect(tf_json[:resource][:aws_subnet]).to have_key(:test_network_public_subnet_0)
      expect(tf_json[:resource][:aws_subnet][:test_network_public_subnet_0][:cidr_block]).to eq('10.0.0.0/18')
    end

    it 'creates internet gateway for public subnets' do
      expect(subject.internet_gateway.type).to eq('aws_internet_gateway')
      expect(subject.internet_gateway.name).to eq(:test_network_igw)
      expect(subject.internet_gateway.resource_attributes[:vpc_id]).to eq(subject.vpc.ref(:id))
    end

    it 'creates NAT gateways for private subnets' do
      expect(subject.nat_gateways.size).to eq(2)
      
      subject.nat_gateways.each_with_index do |nat, index|
        expect(nat.type).to eq('aws_nat_gateway')
        expect(nat.name).to eq(:"test_network_nat_#{index}")
        expect(nat.resource_attributes[:subnet_id]).to eq(subject.public_subnets[index].ref(:id))
      end
    end

    it 'creates route tables with proper routes' do
      # Public route table
      expect(subject.public_route_table.type).to eq('aws_route_table')
      expect(subject.public_route_table.resource_attributes[:vpc_id]).to eq(subject.vpc.ref(:id))
      
      # Should have route to internet gateway
      public_routes = subject.public_route_table.resource_attributes[:routes]
      internet_route = public_routes.find { |r| r[:cidr_block] == '0.0.0.0/0' }
      expect(internet_route[:gateway_id]).to eq(subject.internet_gateway.ref(:id))

      # Private route tables (one per AZ for HA)
      expect(subject.private_route_tables.size).to eq(2)
      
      subject.private_route_tables.each_with_index do |route_table, index|
        expect(route_table.type).to eq('aws_route_table')
        expect(route_table.resource_attributes[:vpc_id]).to eq(subject.vpc.ref(:id))
        
        # Should have route to corresponding NAT gateway
        private_routes = route_table.resource_attributes[:routes]
        nat_route = private_routes.find { |r| r[:cidr_block] == '0.0.0.0/0' }
        expect(nat_route[:nat_gateway_id]).to eq(subject.nat_gateways[index].ref(:id))
      end
    end

    it 'provides convenience methods for subnet IDs' do
      public_ids = subject.public_subnet_ids
      expect(public_ids.size).to eq(2)
      expect(public_ids.first).to match(/\$\{aws_subnet\.test_network_public_subnet_0\.id\}/)
      
      private_ids = subject.private_subnet_ids  
      expect(private_ids.size).to eq(2)
      expect(private_ids.first).to match(/\$\{aws_subnet\.test_network_private_subnet_0\.id\}/)
      
      all_ids = subject.all_subnet_ids
      expect(all_ids.size).to eq(4)
      expect(all_ids).to eq(public_ids + private_ids)
    end

    it 'provides all resources for tracking' do
      all_resources = subject.all_resources
      
      # Should include VPC, subnets, IGW, NAT gateways, route tables, and associations
      expect(all_resources.count).to be >= 15  # At minimum: VPC + 4 subnets + IGW + 2 NATs + 3 route tables + associations
      
      # Verify resource types are included
      resource_types = all_resources.map(&:type).uniq
      expect(resource_types).to include('aws_vpc', 'aws_subnet', 'aws_internet_gateway', 
                                       'aws_nat_gateway', 'aws_route_table')
    end

    context 'with single availability zone' do
      let(:single_az_attributes) do
        vpc_attributes.merge(availability_zones: ['us-east-1a'])
      end

      subject do
        result = nil
        attributes = single_az_attributes
        
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          result = vpc_with_subnets(:single_az, **attributes)
        end
        result
      end

      it 'creates resources for single AZ' do
        expect(subject.public_subnets.size).to eq(1)
        expect(subject.private_subnets.size).to eq(1)
        expect(subject.nat_gateways.size).to eq(1)
        expect(subject.private_route_tables.size).to eq(1)
      end

      it 'calculates CIDR blocks correctly for fewer subnets' do
        # With /16 VPC and 2 subnets, should get /17 subnets
        expected_cidrs = ['10.0.0.0/17', '10.0.128.0/17']
        actual_cidrs = (subject.public_subnets + subject.private_subnets)
                       .map { |subnet| subnet.resource_attributes[:cidr_block] }
        
        expect(actual_cidrs).to eq(expected_cidrs)
      end
    end

    context 'with custom CIDR blocks' do
      let(:custom_cidr_attributes) do
        vpc_attributes.merge(
          vpc_cidr: '172.16.0.0/16',
          public_subnet_cidrs: ['172.16.1.0/24', '172.16.2.0/24'],
          private_subnet_cidrs: ['172.16.10.0/24', '172.16.20.0/24']
        )
      end

      subject do
        result = nil
        attributes = custom_cidr_attributes
        
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          result = vpc_with_subnets(:custom_cidr, **attributes)
        end
        result
      end

      it 'uses custom CIDR blocks when provided' do
        public_cidrs = subject.public_subnets.map { |s| s.resource_attributes[:cidr_block] }
        private_cidrs = subject.private_subnets.map { |s| s.resource_attributes[:cidr_block] }
        
        expect(public_cidrs).to eq(['172.16.1.0/24', '172.16.2.0/24'])
        expect(private_cidrs).to eq(['172.16.10.0/24', '172.16.20.0/24'])
      end
    end
  end

  describe '#auto_scaling_web_tier' do
    let(:vpc_ref) do
      Pangea::Resources::ResourceReference.new(
        type: 'aws_vpc',
        name: :test_vpc,
        resource_attributes: { cidr_block: '10.0.0.0/16' },
        outputs: { id: '${aws_vpc.test_vpc.id}' }
      )
    end
    
    let(:subnet_refs) do
      [
        Pangea::Resources::ResourceReference.new(
          type: 'aws_subnet',
          name: :public_subnet_0,
          resource_attributes: { cidr_block: '10.0.1.0/24' },
          outputs: { id: '${aws_subnet.public_subnet_0.id}' }
        ),
        Pangea::Resources::ResourceReference.new(
          type: 'aws_subnet',
          name: :public_subnet_1,
          resource_attributes: { cidr_block: '10.0.2.0/24' },
          outputs: { id: '${aws_subnet.public_subnet_1.id}' }
        )
      ]
    end

    let(:web_tier_attributes) do
      {
        vpc_ref: vpc_ref,
        subnet_refs: subnet_refs,
        instance_type: 't3.small',
        min_instances: 2,
        max_instances: 10,
        desired_instances: 3,
        ami_id: 'ami-12345678',
        key_name: 'test-key',
        user_data: Base64.strict_encode64("#!/bin/bash\necho 'Hello World'"),
        health_check_path: '/health',
        tags: { Environment: 'test', Tier: 'web' }
      }
    end

    subject do
      result = nil
      attributes = web_tier_attributes
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        result = auto_scaling_web_tier(:web_tier, **attributes)
      end
      result
    end

    it 'returns a CompositeWebServerReference' do
      expect(subject).to be_a(Pangea::Resources::CompositeWebServerReference)
    end

    it 'creates security group with proper rules' do
      sg = subject.security_group
      
      expect(sg.type).to eq('aws_security_group')
      expect(sg.name).to eq(:web_tier_sg)
      expect(sg.resource_attributes[:vpc_id]).to eq(vpc_ref.id)
      
      # Should have HTTP and HTTPS ingress rules
      ingress_rules = sg.resource_attributes[:ingress_rules]
      http_rule = ingress_rules.find { |r| r[:from_port] == 80 }
      https_rule = ingress_rules.find { |r| r[:from_port] == 443 }
      
      expect(http_rule).not_to be_nil
      expect(https_rule).not_to be_nil
      expect(http_rule[:protocol]).to eq('tcp')
      expect(https_rule[:protocol]).to eq('tcp')
    end

    it 'creates launch template with correct configuration' do
      lt = subject.launch_template
      
      expect(lt.type).to eq('aws_launch_template')
      expect(lt.name).to eq(:web_tier_launch_template)
      expect(lt.resource_attributes[:image_id]).to eq('ami-12345678')
      expect(lt.resource_attributes[:instance_type]).to eq('t3.small')
      expect(lt.resource_attributes[:key_name]).to eq('test-key')
      expect(lt.resource_attributes[:user_data]).not_to be_nil
      
      # Should reference security group
      expect(lt.resource_attributes[:vpc_security_group_ids]).to include(subject.security_group.ref(:id))
    end

    it 'creates auto scaling group with proper scaling configuration' do
      asg = subject.auto_scaling_group
      
      expect(asg.type).to eq('aws_autoscaling_group')
      expect(asg.name).to eq(:web_tier_asg)
      expect(asg.resource_attributes[:min_size]).to eq(2)
      expect(asg.resource_attributes[:max_size]).to eq(10)
      expect(asg.resource_attributes[:desired_capacity]).to eq(3)
      
      # Should use launch template
      expect(asg.resource_attributes[:launch_template][:id]).to eq(subject.launch_template.ref(:id))
      
      # Should be in provided subnets
      expect(asg.resource_attributes[:vpc_zone_identifier]).to eq(subnet_refs.map(&:id))
    end

    it 'creates target group for load balancer integration' do
      tg = subject.target_group
      
      expect(tg.type).to eq('aws_lb_target_group')
      expect(tg.name).to eq(:web_tier_target_group)
      expect(tg.resource_attributes[:vpc_id]).to eq(vpc_ref.id)
      expect(tg.resource_attributes[:port]).to eq(80)
      expect(tg.resource_attributes[:protocol]).to eq('HTTP')
      
      # Should have health check configuration
      health_check = tg.resource_attributes[:health_check]
      expect(health_check[:path]).to eq('/health')
      expect(health_check[:healthy_threshold]).not_to be_nil
    end

    it 'creates auto scaling group attachment to target group' do
      attachment = subject.asg_attachment
      
      expect(attachment.type).to eq('aws_autoscaling_attachment')
      expect(attachment.resource_attributes[:autoscaling_group_name]).to eq(subject.auto_scaling_group.ref(:name))
      expect(attachment.resource_attributes[:lb_target_group_arn]).to eq(subject.target_group.ref(:arn))
    end

    it 'creates scaling policies for auto scaling' do
      scale_up = subject.scale_up_policy
      scale_down = subject.scale_down_policy
      
      expect(scale_up.type).to eq('aws_autoscaling_policy')
      expect(scale_down.type).to eq('aws_autoscaling_policy')
      
      expect(scale_up.resource_attributes[:scaling_adjustment]).to be > 0
      expect(scale_down.resource_attributes[:scaling_adjustment]).to be < 0
      
      expect(scale_up.resource_attributes[:autoscaling_group_name]).to eq(subject.auto_scaling_group.ref(:name))
      expect(scale_down.resource_attributes[:autoscaling_group_name]).to eq(subject.auto_scaling_group.ref(:name))
    end

    it 'creates CloudWatch alarms for scaling triggers' do
      high_cpu_alarm = subject.cpu_high_alarm
      low_cpu_alarm = subject.cpu_low_alarm
      
      expect(high_cpu_alarm.type).to eq('aws_cloudwatch_metric_alarm')
      expect(low_cpu_alarm.type).to eq('aws_cloudwatch_metric_alarm')
      
      # High CPU alarm should trigger scale up
      expect(high_cpu_alarm.resource_attributes[:alarm_actions]).to include(subject.scale_up_policy.ref(:arn))
      
      # Low CPU alarm should trigger scale down  
      expect(low_cpu_alarm.resource_attributes[:alarm_actions]).to include(subject.scale_down_policy.ref(:arn))
      
      # Both should monitor CPU utilization
      expect(high_cpu_alarm.resource_attributes[:metric_name]).to eq('CPUUtilization')
      expect(low_cpu_alarm.resource_attributes[:metric_name]).to eq('CPUUtilization')
    end

    it 'provides all resources for tracking' do
      all_resources = subject.all_resources
      
      # Should include security group, launch template, ASG, target group, 
      # attachment, scaling policies, and alarms
      expect(all_resources.count).to be >= 8
      
      resource_types = all_resources.map(&:type).uniq
      expect(resource_types).to include(
        'aws_security_group',
        'aws_launch_template', 
        'aws_autoscaling_group',
        'aws_lb_target_group',
        'aws_autoscaling_attachment',
        'aws_autoscaling_policy',
        'aws_cloudwatch_metric_alarm'
      )
    end

    it 'provides convenience methods' do
      expect(subject.min_instances).to eq(2)
      expect(subject.max_instances).to eq(10)
      expect(subject.desired_instances).to eq(3)
      expect(subject.instance_type).to eq('t3.small')
    end
  end

  describe 'composition validation' do
    it 'validates VPC CIDR format in vpc_with_subnets' do
      invalid_attributes = {
        vpc_cidr: 'invalid-cidr',
        availability_zones: ['us-east-1a']
      }
      
      expect {
        attributes = invalid_attributes
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          vpc_with_subnets(:invalid, **attributes)
        end
      }.to raise_error(Dry::Struct::Error, /vpc_cidr/)
    end

    it 'validates availability zones are provided' do
      invalid_attributes = {
        vpc_cidr: '10.0.0.0/16',
        availability_zones: []
      }
      
      expect {
        attributes = invalid_attributes
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          vpc_with_subnets(:invalid, **attributes)
        end
      }.to raise_error(ArgumentError)
    end

    it 'validates scaling parameters in auto_scaling_web_tier' do
      invalid_attributes = {
        vpc_ref: Pangea::Resources::ResourceReference.new(
          type: 'aws_vpc',
          name: :test_vpc,
          resource_attributes: { cidr_block: '10.0.0.0/16' },
          outputs: { id: '${aws_vpc.test_vpc.id}' }
        ),
        subnet_refs: [
          Pangea::Resources::ResourceReference.new(
            type: 'aws_subnet',
            name: :public_subnet_0,
            resource_attributes: { cidr_block: '10.0.1.0/24' },
            outputs: { id: '${aws_subnet.public_subnet_0.id}' }
          )
        ],
        min_instances: 5,
        max_instances: 2  # Max < Min
      }
      
      expect {
        attributes = invalid_attributes
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          auto_scaling_web_tier(:invalid, **attributes)
        end
      }.to raise_error(Dry::Struct::Error)
    end
  end

  describe 'resource naming consistency' do
    it 'maintains consistent naming patterns' do
      vpc_comp = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        vpc_comp = vpc_with_subnets(:test_vpc, 
          vpc_cidr: '10.0.0.0/16',
          availability_zones: ['us-east-1a', 'us-east-1b']
        )
      end
      
      # All resource names should start with the base name
      vpc_comp.all_resources.each do |resource|
        expect(resource.name.to_s).to start_with('test_vpc_')
      end
      
      # Verify terraform synthesis
      tf_json = synthesizer.synthesis
      expect(tf_json[:resource][:aws_vpc]).to have_key(:test_vpc_vpc)
    end

    it 'uses descriptive suffixes for different resource types' do
      vpc_comp = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        vpc_comp = vpc_with_subnets(:network, 
          vpc_cidr: '10.0.0.0/16',
          availability_zones: ['us-east-1a']
        )
      end
      
      expect(vpc_comp.vpc.name).to eq(:network_vpc)
      expect(vpc_comp.internet_gateway.name).to eq(:network_igw)
      expect(vpc_comp.public_subnets.first.name).to eq(:network_public_subnet_0)
      expect(vpc_comp.private_subnets.first.name).to eq(:network_private_subnet_0)
      expect(vpc_comp.nat_gateways.first.name).to eq(:network_nat_0)
      
      # Verify terraform synthesis
      tf_json = synthesizer.synthesis
      expect(tf_json[:resource][:aws_vpc]).to have_key(:network_vpc)
      expect(tf_json[:resource][:aws_internet_gateway]).to have_key(:network_igw)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:network_public_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:network_private_subnet_0)
      expect(tf_json[:resource][:aws_nat_gateway]).to have_key(:network_nat_0)
    end
  end

end