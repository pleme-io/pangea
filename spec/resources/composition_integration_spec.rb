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

RSpec.describe 'Pangea Resource Composition - Terraform Synthesizer Integration' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'VPC with Multi-AZ Subnets Architecture' do
    it 'synthesizes a complete VPC architecture with public and private subnets' do
      # Execute within terraform synthesizer context
      vpc_result = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        vpc_result = vpc_with_subnets(:production,
          vpc_cidr: '10.0.0.0/16',
          availability_zones: ['us-east-1a', 'us-east-1b'],
          attributes: {
            vpc_tags: { Environment: 'production', ManagedBy: 'pangea' },
            public_subnet_tags: { Tier: 'public' },
            private_subnet_tags: { Tier: 'private' }
          }
        )
      end
      
      # Verify the composite reference structure outside synthesizer context
      expect(vpc_result).to be_a(Pangea::Resources::CompositeVpcReference)
      expect(vpc_result.vpc).not_to be_nil
      expect(vpc_result.internet_gateway).not_to be_nil
      expect(vpc_result.public_subnets.size).to eq(2)
      expect(vpc_result.private_subnets.size).to eq(2)
      expect(vpc_result.nat_gateways.size).to eq(2)
      
      # Synthesize to terraform JSON
      tf_json = synthesizer.synthesis
      
      # Verify VPC resource
      expect(tf_json[:resource][:aws_vpc]).to have_key(:production_vpc)
      vpc_config = tf_json[:resource][:aws_vpc][:production_vpc]
      expect(vpc_config[:cidr_block]).to eq('10.0.0.0/16')
      expect(vpc_config[:enable_dns_hostnames]).to be true
      expect(vpc_config[:tags][:Environment]).to eq('production')
      
      # Verify Internet Gateway
      expect(tf_json[:resource][:aws_internet_gateway]).to have_key(:production_igw)
      igw_config = tf_json[:resource][:aws_internet_gateway][:production_igw]
      expect(igw_config[:vpc_id]).to eq('${aws_vpc.production_vpc.id}')
      
      # Verify Subnets
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_public_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_public_subnet_1)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_private_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_private_subnet_1)
      
      # Verify NAT Gateways
      expect(tf_json[:resource][:aws_nat_gateway]).to have_key(:production_nat_0)
      expect(tf_json[:resource][:aws_nat_gateway]).to have_key(:production_nat_1)
      
      # Verify Route Tables
      expect(tf_json[:resource][:aws_route_table]).to have_key(:production_public_rt)
      expect(tf_json[:resource][:aws_route_table]).to have_key(:production_private_rt_0)
      expect(tf_json[:resource][:aws_route_table]).to have_key(:production_private_rt_1)
    end
  end
  
  describe 'Auto-Scaling Web Tier Architecture' do
    it 'synthesizes a complete auto-scaling web application infrastructure' do
      network = nil
      web_tier = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        # First create a VPC for the web tier
        network = vpc_with_subnets(:webapp,
          vpc_cidr: '10.1.0.0/16',
          availability_zones: ['us-east-1a', 'us-east-1b']
        )
        
        # Create auto-scaling web tier
        web_tier = auto_scaling_web_tier(:frontend,
          vpc_ref: network.vpc,
          subnet_refs: network.public_subnets,
          instance_type: 't3.medium',
          min_instances: 2,
          max_instances: 10,
          desired_instances: 4,
          ami_id: 'ami-0abcdef1234567890',
          health_check_path: '/api/health',
          tags: { Application: 'webapp', Tier: 'frontend' }
        )
      end
      
      # Verify outside synthesizer context
      expect(web_tier).to be_a(Pangea::Resources::CompositeWebServerReference)
      expect(web_tier.security_group).not_to be_nil
      expect(web_tier.launch_template).not_to be_nil
      expect(web_tier.auto_scaling_group).not_to be_nil
      expect(web_tier.target_group).not_to be_nil
      
      tf_json = synthesizer.synthesis
      
      # Verify Security Group
      expect(tf_json[:resource][:aws_security_group]).to have_key(:frontend_sg)
      sg_config = tf_json[:resource][:aws_security_group][:frontend_sg]
      expect(sg_config[:vpc_id]).to eq('${aws_vpc.webapp_vpc.id}')
      expect(sg_config[:ingress]).to include(
        hash_including(from_port: 80, to_port: 80, protocol: 'tcp')
      )
      
      # Verify Launch Template
      expect(tf_json[:resource][:aws_launch_template]).to have_key(:frontend_launch_template)
      lt_config = tf_json[:resource][:aws_launch_template][:frontend_launch_template]
      expect(lt_config[:launch_template_data][:instance_type]).to eq('t3.medium')
      
      # Verify Auto Scaling Group
      expect(tf_json[:resource][:aws_autoscaling_group]).to have_key(:frontend_asg)
      asg_config = tf_json[:resource][:aws_autoscaling_group][:frontend_asg]
      expect(asg_config[:min_size]).to eq(2)
      expect(asg_config[:max_size]).to eq(10)
      expect(asg_config[:desired_capacity]).to eq(4)
      
      # Verify CloudWatch Alarms
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:frontend_cpu_high)
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:frontend_cpu_low)
    end
  end
  
  describe 'Complex Multi-Tier Application Architecture' do
    it 'synthesizes a complete three-tier application with networking, compute, and data layers' do
      network = nil
      web_tier = nil
      app_tier = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        # Create base network infrastructure
        network = vpc_with_subnets(:threetier,
          vpc_cidr: '10.2.0.0/16',
          availability_zones: ['us-west-2a', 'us-west-2b', 'us-west-2c'],
          attributes: {
            vpc_tags: { Project: 'ThreeTierApp', CostCenter: 'Engineering' }
          }
        )
        
        # Web tier in public subnets
        web_tier = auto_scaling_web_tier(:web,
          vpc_ref: network.vpc,
          subnet_refs: network.public_subnets,
          instance_type: 't3.small',
          min_instances: 3,
          max_instances: 9,
          tags: { Layer: 'presentation' }
        )
        
        # App tier in private subnets
        app_tier = auto_scaling_web_tier(:app,
          vpc_ref: network.vpc,
          subnet_refs: network.private_subnets,
          instance_type: 't3.large',
          min_instances: 2,
          max_instances: 6,
          tags: { Layer: 'application' }
        )
      end
      
      # Verify complete architecture outside synthesizer
      expect(network.public_subnets.size).to eq(3)
      expect(network.private_subnets.size).to eq(3)
      expect(network.nat_gateways.size).to eq(3)
      expect(web_tier.all_resources.size).to be >= 8
      expect(app_tier.all_resources.size).to be >= 8
      
      tf_json = synthesizer.synthesis
      
      # Verify the complete infrastructure was synthesized
      expect(tf_json[:resource][:aws_vpc]).to have_key(:threetier_vpc)
      expect(tf_json[:resource][:aws_subnet].keys.size).to eq(6) # 3 public + 3 private
      expect(tf_json[:resource][:aws_nat_gateway].keys.size).to eq(3)
      expect(tf_json[:resource][:aws_autoscaling_group]).to have_key(:web_asg)
      expect(tf_json[:resource][:aws_autoscaling_group]).to have_key(:app_asg)
    end
  end
  
  describe 'Edge Cases and Validation' do
    it 'handles single availability zone deployments correctly' do
      small_network = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        small_network = vpc_with_subnets(:small,
          vpc_cidr: '10.3.0.0/24',
          availability_zones: ['eu-west-1a']
        )
      end
      
      expect(small_network.public_subnets.size).to eq(1)
      expect(small_network.private_subnets.size).to eq(1)
      expect(small_network.nat_gateways.size).to eq(1)
      
      tf_json = synthesizer.synthesis
      
      # Verify smaller CIDR calculations work
      public_subnet = tf_json[:resource][:aws_subnet][:small_public_subnet_0]
      private_subnet = tf_json[:resource][:aws_subnet][:small_private_subnet_0]
      
      expect(public_subnet[:cidr_block]).to eq('10.3.0.0/25')
      expect(private_subnet[:cidr_block]).to eq('10.3.0.128/25')
    end
    
    it 'validates invalid VPC CIDR blocks' do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          vpc_with_subnets(:invalid,
            vpc_cidr: 'not-a-valid-cidr',
            availability_zones: ['us-east-1a']
          )
        end
      }.to raise_error(Dry::Struct::Error)
    end
    
    it 'handles custom subnet CIDR blocks correctly' do
      custom_network = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        custom_network = vpc_with_subnets(:custom,
          vpc_cidr: '192.168.0.0/16',
          availability_zones: ['ap-south-1a', 'ap-south-1b'],
          public_subnet_cidrs: ['192.168.1.0/24', '192.168.2.0/24'],
          private_subnet_cidrs: ['192.168.100.0/24', '192.168.101.0/24']
        )
      end
      
      expect(custom_network.public_subnets[0].resource_attributes[:cidr_block]).to eq('192.168.1.0/24')
      expect(custom_network.public_subnets[1].resource_attributes[:cidr_block]).to eq('192.168.2.0/24')
      expect(custom_network.private_subnets[0].resource_attributes[:cidr_block]).to eq('192.168.100.0/24')
      expect(custom_network.private_subnets[1].resource_attributes[:cidr_block]).to eq('192.168.101.0/24')
    end
  end
  
  describe 'Resource Naming Conventions' do
    it 'maintains consistent and descriptive naming patterns' do
      network = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        network = vpc_with_subnets(:myapp,
          vpc_cidr: '10.4.0.0/16',
          availability_zones: ['us-east-1a']
        )
      end
      
      # All resources should have consistent naming
      expect(network.vpc.name).to eq(:myapp_vpc)
      expect(network.internet_gateway.name).to eq(:myapp_igw)
      expect(network.public_subnets.first.name).to eq(:myapp_public_subnet_0)
      expect(network.private_subnets.first.name).to eq(:myapp_private_subnet_0)
      expect(network.nat_gateways.first.name).to eq(:myapp_nat_0)
      expect(network.public_route_table.name).to eq(:myapp_public_rt)
      expect(network.private_route_tables.first.name).to eq(:myapp_private_rt_0)
    end
  end
end