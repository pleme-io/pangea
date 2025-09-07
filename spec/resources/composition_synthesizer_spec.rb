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

    it 'synthesizes complete VPC infrastructure with terraform-synthesizer' do
      result = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        result = vpc_with_subnets(:test_network, **vpc_attributes)
      end
      
      # Verify the result structure
      expect(result).to be_a(Pangea::Resources::CompositeVpcReference)
      expect(result.vpc.type).to eq('aws_vpc')
      expect(result.vpc.name).to eq(:test_network_vpc)
      expect(result.public_subnets.size).to eq(2)
      expect(result.private_subnets.size).to eq(2)
      expect(result.nat_gateways.size).to eq(2)
      
      # Get the synthesized terraform JSON
      tf_json = synthesizer.synthesis
      
      # Verify VPC was created correctly
      expect(tf_json[:resource][:aws_vpc]).to have_key(:test_network_vpc)
      vpc_config = tf_json[:resource][:aws_vpc][:test_network_vpc]
      expect(vpc_config[:cidr_block]).to eq('10.0.0.0/16')
      expect(vpc_config[:enable_dns_hostnames]).to be true
      expect(vpc_config[:enable_dns_support]).to be true
      expect(vpc_config[:tags][:Name]).to eq('test-vpc')
      expect(vpc_config[:tags][:Environment]).to eq('test')
      
      # Verify Internet Gateway
      expect(tf_json[:resource][:aws_internet_gateway]).to have_key(:test_network_igw)
      igw_config = tf_json[:resource][:aws_internet_gateway][:test_network_igw]
      expect(igw_config[:vpc_id]).to eq('${aws_vpc.test_network_vpc.id}')
      
      # Verify Subnets
      expect(tf_json[:resource][:aws_subnet]).to have_key(:test_network_public_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:test_network_public_subnet_1)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:test_network_private_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:test_network_private_subnet_1)
      
      # Verify public subnet configuration
      public_subnet = tf_json[:resource][:aws_subnet][:test_network_public_subnet_0]
      expect(public_subnet[:vpc_id]).to eq('${aws_vpc.test_network_vpc.id}')
      expect(public_subnet[:cidr_block]).to eq('10.0.0.0/18')
      expect(public_subnet[:availability_zone]).to eq('us-east-1a')
      expect(public_subnet[:map_public_ip_on_launch]).to be true
      expect(public_subnet[:tags][:Type]).to eq('public')
      
      # Verify NAT Gateways
      expect(tf_json[:resource][:aws_nat_gateway]).to have_key(:test_network_nat_0)
      expect(tf_json[:resource][:aws_nat_gateway]).to have_key(:test_network_nat_1)
      nat_config = tf_json[:resource][:aws_nat_gateway][:test_network_nat_0]
      expect(nat_config[:subnet_id]).to eq('${aws_subnet.test_network_public_subnet_0.id}')
      
      # Verify Route Tables
      expect(tf_json[:resource][:aws_route_table]).to have_key(:test_network_public_rt)
      expect(tf_json[:resource][:aws_route_table]).to have_key(:test_network_private_rt_0)
      expect(tf_json[:resource][:aws_route_table]).to have_key(:test_network_private_rt_1)
      
      # Verify public route table has internet gateway route
      public_rt = tf_json[:resource][:aws_route_table][:test_network_public_rt]
      expect(public_rt[:routes]).to be_an(Array)
      expect(public_rt[:routes].first[:cidr_block]).to eq('0.0.0.0/0')
      expect(public_rt[:routes].first[:gateway_id]).to eq('${aws_internet_gateway.test_network_igw.id}')
      
      # Verify private route tables have NAT gateway routes
      private_rt = tf_json[:resource][:aws_route_table][:test_network_private_rt_0]
      expect(private_rt[:routes]).to be_an(Array)
      expect(private_rt[:routes].first[:cidr_block]).to eq('0.0.0.0/0')
      expect(private_rt[:routes].first[:nat_gateway_id]).to eq('${aws_nat_gateway.test_network_nat_0.id}')
    end
    
    it 'calculates correct CIDR blocks for subnets' do
      result = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        result = vpc_with_subnets(:test_network, **vpc_attributes)
      end
      
      tf_json = synthesizer.synthesis
      
      # With /16 VPC and 4 subnets (2 public, 2 private), should get /18 subnets
      expected_cidrs = {
        test_network_public_subnet_0: '10.0.0.0/18',
        test_network_public_subnet_1: '10.0.64.0/18',
        test_network_private_subnet_0: '10.0.128.0/18',
        test_network_private_subnet_1: '10.0.192.0/18'
      }
      
      expected_cidrs.each do |subnet_name, expected_cidr|
        actual_cidr = tf_json[:resource][:aws_subnet][subnet_name][:cidr_block]
        expect(actual_cidr).to eq(expected_cidr)
      end
    end
    
    context 'with single availability zone' do
      let(:single_az_attributes) do
        vpc_attributes.merge(availability_zones: ['us-east-1a'])
      end

      it 'creates resources for single AZ with terraform synthesis' do
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          vpc_with_subnets(:single_az, **single_az_attributes)
        end
        
        tf_json = synthesizer.synthesis
        
        # Should have exactly 1 public and 1 private subnet
        subnets = tf_json[:resource][:aws_subnet]
        expect(subnets.keys).to contain_exactly(
          :single_az_public_subnet_0,
          :single_az_private_subnet_0
        )
        
        # Should have exactly 1 NAT gateway
        nat_gateways = tf_json[:resource][:aws_nat_gateway]
        expect(nat_gateways.keys).to contain_exactly(:single_az_nat_0)
        
        # Should have 1 public and 1 private route table
        route_tables = tf_json[:resource][:aws_route_table]
        expect(route_tables.keys).to contain_exactly(
          :single_az_public_rt,
          :single_az_private_rt_0
        )
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

      it 'uses custom CIDR blocks when provided' do
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          vpc_with_subnets(:custom_cidr, **custom_cidr_attributes)
        end
        
        tf_json = synthesizer.synthesis
        
        # Verify custom CIDR blocks are used
        expect(tf_json[:resource][:aws_subnet][:custom_cidr_public_subnet_0][:cidr_block]).to eq('172.16.1.0/24')
        expect(tf_json[:resource][:aws_subnet][:custom_cidr_public_subnet_1][:cidr_block]).to eq('172.16.2.0/24')
        expect(tf_json[:resource][:aws_subnet][:custom_cidr_private_subnet_0][:cidr_block]).to eq('172.16.10.0/24')
        expect(tf_json[:resource][:aws_subnet][:custom_cidr_private_subnet_1][:cidr_block]).to eq('172.16.20.0/24')
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

    it 'synthesizes complete auto-scaling infrastructure' do
      result = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        result = auto_scaling_web_tier(:web_tier, **web_tier_attributes)
      end
      
      # Verify result structure
      expect(result).to be_a(Pangea::Resources::CompositeWebServerReference)
      expect(result.security_group).not_to be_nil
      expect(result.launch_template).not_to be_nil
      expect(result.auto_scaling_group).not_to be_nil
      expect(result.target_group).not_to be_nil
      
      # Get synthesized terraform JSON
      tf_json = synthesizer.synthesis
      
      # Verify Security Group with proper rules
      expect(tf_json[:resource][:aws_security_group]).to have_key(:web_tier_sg)
      sg_config = tf_json[:resource][:aws_security_group][:web_tier_sg]
      expect(sg_config[:vpc_id]).to eq('${aws_vpc.test_vpc.id}')
      expect(sg_config[:ingress]).to be_an(Array)
      expect(sg_config[:ingress].any? { |r| r[:from_port] == 80 }).to be true
      expect(sg_config[:ingress].any? { |r| r[:from_port] == 443 }).to be true
      
      # Verify Launch Template
      expect(tf_json[:resource][:aws_launch_template]).to have_key(:web_tier_launch_template)
      lt_config = tf_json[:resource][:aws_launch_template][:web_tier_launch_template]
      expect(lt_config[:launch_template_data][:image_id]).to eq('ami-12345678')
      expect(lt_config[:launch_template_data][:instance_type]).to eq('t3.small')
      expect(lt_config[:launch_template_data][:key_name]).to eq('test-key')
      expect(lt_config[:launch_template_data][:user_data]).not_to be_nil
      
      # Verify Auto Scaling Group
      expect(tf_json[:resource][:aws_autoscaling_group]).to have_key(:web_tier_asg)
      asg_config = tf_json[:resource][:aws_autoscaling_group][:web_tier_asg]
      expect(asg_config[:min_size]).to eq(2)
      expect(asg_config[:max_size]).to eq(10)
      expect(asg_config[:desired_capacity]).to eq(3)
      expect(asg_config[:vpc_zone_identifier]).to eq([
        '${aws_subnet.public_subnet_0.id}',
        '${aws_subnet.public_subnet_1.id}'
      ])
      
      # Verify Target Group
      expect(tf_json[:resource][:aws_lb_target_group]).to have_key(:web_tier_target_group)
      tg_config = tf_json[:resource][:aws_lb_target_group][:web_tier_target_group]
      expect(tg_config[:port]).to eq(80)
      expect(tg_config[:protocol]).to eq('HTTP')
      expect(tg_config[:vpc_id]).to eq('${aws_vpc.test_vpc.id}')
      expect(tg_config[:health_check][:path]).to eq('/health')
      
      # Verify CloudWatch Alarms
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:web_tier_cpu_high)
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:web_tier_cpu_low)
      
      high_alarm = tf_json[:resource][:aws_cloudwatch_metric_alarm][:web_tier_cpu_high]
      expect(high_alarm[:metric_name]).to eq('CPUUtilization')
      expect(high_alarm[:threshold]).to eq(70)
      expect(high_alarm[:comparison_operator]).to eq('GreaterThanThreshold')
    end
  end
  
  describe 'composition validation' do
    it 'validates VPC CIDR format in vpc_with_subnets' do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          vpc_with_subnets(:invalid,
            vpc_cidr: 'invalid-cidr',
            availability_zones: ['us-east-1a']
          )
        end
      }.to raise_error(Dry::Struct::Error, /vpc_cidr/)
    end
    
    it 'validates availability zones are provided' do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          vpc_with_subnets(:invalid,
            vpc_cidr: '10.0.0.0/16',
            availability_zones: []
          )
        end
      }.to raise_error(ArgumentError)
    end
  end
end