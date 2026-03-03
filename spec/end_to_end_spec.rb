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
require 'json'

RSpec.describe 'Pangea End-to-End: Pure Functions → Terraform Synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'Complete Infrastructure Deployment with Type Safety' do
    it 'synthesizes a production-ready infrastructure using pure functions' do
      # Capture the terraform JSON output
      tf_json = nil
      
      # Execute within synthesizer context
      synthesizer.instance_eval do
        extend Pangea::Resources::Composition
        
        # Deploy a complete infrastructure using type-safe pure functions
        network = vpc_with_subnets(:production,
          vpc_cidr: '10.0.0.0/16',
          availability_zones: ['us-east-1a', 'us-east-1b', 'us-east-1c'],
          attributes: {
            vpc_tags: { 
              Environment: 'production',
              Project: 'pangea-demo',
              ManagedBy: 'terraform'
            }
          }
        )
        
        # Create auto-scaling web tier
        web_tier = auto_scaling_web_tier(:web,
          vpc_ref: network.vpc,
          subnet_refs: network.public_subnets,
          instance_type: 't3.medium',
          min_instances: 3,
          max_instances: 12,
          desired_instances: 6,
          ami_id: 'ami-0c02fb55956c7d316', # Amazon Linux 2 AMI
          health_check_path: '/api/v1/health',
          tags: { 
            Tier: 'web',
            Service: 'frontend'
          }
        )
        
        # Create application tier in private subnets
        app_tier = auto_scaling_web_tier(:app,
          vpc_ref: network.vpc,
          subnet_refs: network.private_subnets,
          instance_type: 'c5.large',
          min_instances: 2,
          max_instances: 8,
          desired_instances: 4,
          ami_id: 'ami-0c02fb55956c7d316',
          health_check_path: '/health',
          tags: {
            Tier: 'application',
            Service: 'backend'
          }
        )
      end
      
      # Get the synthesized terraform JSON
      tf_json = synthesizer.synthesis
      
      # Verify the complete infrastructure was created
      expect(tf_json).to be_a(Hash)
      expect(tf_json[:resource]).to be_a(Hash)
      
      # Verify VPC resources
      expect(tf_json[:resource][:aws_vpc]).to have_key(:production_vpc)
      vpc = tf_json[:resource][:aws_vpc][:production_vpc]
      expect(vpc[:cidr_block]).to eq('10.0.0.0/16')
      expect(vpc[:enable_dns_hostnames]).to be true
      expect(vpc[:tags][:Environment]).to eq('production')
      expect(vpc[:tags][:Project]).to eq('pangea-demo')
      
      # Verify Subnets (3 public + 3 private)
      expect(tf_json[:resource][:aws_subnet].keys.size).to eq(6)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_public_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_public_subnet_1)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_public_subnet_2)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_private_subnet_0)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_private_subnet_1)
      expect(tf_json[:resource][:aws_subnet]).to have_key(:production_private_subnet_2)
      
      # Verify NAT Gateways for high availability
      expect(tf_json[:resource][:aws_nat_gateway].keys.size).to eq(3)
      
      # Verify Auto Scaling Groups
      expect(tf_json[:resource][:aws_autoscaling_group]).to have_key(:web_asg)
      expect(tf_json[:resource][:aws_autoscaling_group]).to have_key(:app_asg)
      
      web_asg = tf_json[:resource][:aws_autoscaling_group][:web_asg]
      expect(web_asg[:min_size]).to eq(3)
      expect(web_asg[:max_size]).to eq(12)
      expect(web_asg[:desired_capacity]).to eq(6)
      
      app_asg = tf_json[:resource][:aws_autoscaling_group][:app_asg]
      expect(app_asg[:min_size]).to eq(2)
      expect(app_asg[:max_size]).to eq(8)
      expect(app_asg[:desired_capacity]).to eq(4)
      
      # Verify Security Groups with proper ingress rules
      expect(tf_json[:resource][:aws_security_group]).to have_key(:web_sg)
      expect(tf_json[:resource][:aws_security_group]).to have_key(:app_sg)
      
      web_sg = tf_json[:resource][:aws_security_group][:web_sg]
      expect(web_sg[:ingress]).to be_an(Array)
      expect(web_sg[:ingress].any? { |r| r[:from_port] == 80 }).to be true
      expect(web_sg[:ingress].any? { |r| r[:from_port] == 443 }).to be true
      
      # Verify CloudWatch Alarms for auto-scaling
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:web_cpu_high)
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:web_cpu_low)
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:app_cpu_high)
      expect(tf_json[:resource][:aws_cloudwatch_metric_alarm]).to have_key(:app_cpu_low)
      
      # Verify proper resource tagging
      web_lt = tf_json[:resource][:aws_launch_template][:web_launch_template]
      expect(web_lt[:tags][:Tier]).to eq('web')
      expect(web_lt[:tags][:Service]).to eq('frontend')
    end
  end
  
  describe 'Type Safety and Validation' do
    it 'validates infrastructure configurations at runtime' do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::Composition
          extend Pangea::Resources::AWS
          
          # This should fail validation
          vpc_with_subnets(:invalid,
            vpc_cidr: 'not-a-valid-cidr-block',
            availability_zones: ['us-east-1a']
          )
        end
      }.to raise_error(Dry::Struct::Error)
    end
    
    it 'enforces type constraints on resource attributes' do
      expect {
        synthesizer.instance_eval do
          extend Pangea::Resources::AWS
          
          # This should fail type validation
          aws_vpc(:test, {
            cidr_block: '10.0.0.0/16',
            enable_dns_support: 'yes' # Should be boolean
          })
        end
      }.to raise_error(Dry::Struct::Error)
    end
  end
  
  describe 'Resource Reference Chain' do
    it 'properly chains resource dependencies through references' do
      tf_json = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        # Create resources with explicit chaining
        vpc = aws_vpc(:main, {
          cidr_block: '172.16.0.0/16',
          tags: { Name: 'reference-test' }
        })
        
        subnet = aws_subnet(:web, {
          vpc_id: vpc.id,  # Reference chain
          cidr_block: '172.16.1.0/24',
          availability_zone: 'us-west-2a',
          map_public_ip_on_launch: true
        })
        
        instance = aws_instance(:app, {
          ami: 'ami-12345678',
          instance_type: 't3.micro',
          subnet_id: subnet.id  # Reference chain
        })
      end
      
      tf_json = synthesizer.synthesis
      
      # Verify reference chains
      subnet_config = tf_json[:resource][:aws_subnet][:web]
      expect(subnet_config[:vpc_id]).to eq('${aws_vpc.main.id}')
      
      instance_config = tf_json[:resource][:aws_instance][:app]
      expect(instance_config[:subnet_id]).to eq('${aws_subnet.web.id}')
    end
  end
  
  describe 'Terraform JSON Output Format' do
    it 'produces valid Terraform JSON syntax' do
      tf_json = nil
      
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        # Create a simple resource
        aws_vpc(:test, {
          cidr_block: '10.0.0.0/24',
          enable_dns_support: true,
          enable_dns_hostnames: true,
          tags: {
            Name: 'test-vpc',
            Environment: 'test'
          }
        })
      end
      
      tf_json = synthesizer.synthesis
      
      # The JSON should be serializable
      json_string = JSON.pretty_generate(tf_json)
      expect { JSON.parse(json_string) }.not_to raise_error
      
      # Verify structure matches Terraform expectations
      expect(tf_json).to have_key(:resource)
      expect(tf_json[:resource]).to have_key(:aws_vpc)
      expect(tf_json[:resource][:aws_vpc]).to have_key(:test)
    end
  end
end