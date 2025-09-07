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

RSpec.describe "Pangea Type System - Pure Functions" do
  describe "AWS Region validation" do
    let(:region_type) { Pangea::Resources::Types::AwsRegion }
    
    it "accepts valid AWS regions" do
      valid_regions = ['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1']
      valid_regions.each do |region|
        expect { region_type[region] }.not_to raise_error
        expect(region_type[region]).to eq(region)
      end
    end
    
    it "rejects invalid AWS regions" do
      invalid_regions = ['invalid-region', 'us-east-99', '', nil]
      invalid_regions.each do |region|
        expect { region_type[region] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "CIDR Block validation" do
    let(:cidr_type) { Pangea::Resources::Types::CidrBlock }
    
    it "accepts valid CIDR blocks" do
      valid_cidrs = ['10.0.0.0/16', '172.16.0.0/12', '192.168.0.0/24', '0.0.0.0/0']
      valid_cidrs.each do |cidr|
        expect { cidr_type[cidr] }.not_to raise_error
        expect(cidr_type[cidr]).to eq(cidr)
      end
    end
    
    it "rejects invalid CIDR blocks" do
      invalid_cidrs = ['10.0.0.0', '256.0.0.0/16', '10.0.0.0/33', 'not-a-cidr', '', nil]
      invalid_cidrs.each do |cidr|
        expect { cidr_type[cidr] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "EC2 Instance Type validation" do
    let(:instance_type) { Pangea::Resources::Types::Ec2InstanceType }
    
    it "accepts valid EC2 instance types" do
      valid_types = ['t3.micro', 't3.small', 'm5.large', 'c5.xlarge', 'r5.2xlarge']
      valid_types.each do |type|
        expect { instance_type[type] }.not_to raise_error
        expect(instance_type[type]).to eq(type)
      end
    end
    
    it "rejects invalid EC2 instance types" do
      invalid_types = ['invalid.type', 't2.micro', 't2.invalid', '', nil]
      invalid_types.each do |type|
        expect { instance_type[type] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "Port validation" do
    let(:port_type) { Pangea::Resources::Types::Port }
    
    it "accepts valid port numbers" do
      valid_ports = [0, 22, 80, 443, 3000, 8080, 65535]
      valid_ports.each do |port|
        expect { port_type[port] }.not_to raise_error
        expect(port_type[port]).to eq(port)
      end
    end
    
    it "rejects invalid port numbers" do
      invalid_ports = [-1, 65536, 100000, nil]
      invalid_ports.each do |port|
        expect { port_type[port] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "AWS Tags validation" do
    let(:tags_type) { Pangea::Resources::Types::AwsTags }
    
    it "accepts valid tag hashes" do
      valid_tags = [
        { Name: 'test-resource' },
        { Name: 'test', Environment: 'production' },
        {}
      ]
      
      valid_tags.each do |tags|
        expect { tags_type[tags] }.not_to raise_error
      end
    end
    
    it "requires symbol keys in tags" do
      # Tags type expects symbols, not strings
      tags = { 'Name' => 'test', 'Environment' => 'prod' }
      expect { tags_type[tags] }.to raise_error(Dry::Types::MapError)
    end
  end

  describe "SecurityGroupRule validation" do
    let(:rule_type) { Pangea::Resources::Types::SecurityGroupRule }
    
    it "accepts valid security group rules" do
      valid_rule = {
        from_port: 80,
        to_port: 80,
        protocol: 'tcp',
        cidr_blocks: ['0.0.0.0/0']
      }
      
      expect { rule_type[valid_rule] }.not_to raise_error
    end
    
    it "validates port ranges" do
      invalid_rule = {
        from_port: 80,
        to_port: 80,
        protocol: 'tcp',
        cidr_blocks: ['0.0.0.0/0']
      }
      
      expect { rule_type[invalid_rule] }.to raise_error(Dry::Types::SchemaError)
    end
  end

  describe "Instance Tenancy validation" do
    let(:tenancy_type) { Pangea::Resources::Types::InstanceTenancy }
    
    it "accepts valid tenancy values" do
      valid_values = ['default', 'dedicated', 'host']
      valid_values.each do |value|
        expect { tenancy_type[value] }.not_to raise_error
        expect(tenancy_type[value]).to eq(value)
      end
    end
    
    it "rejects invalid tenancy values" do
      invalid_values = ['shared', 'invalid', '', nil]
      invalid_values.each do |value|
        expect { tenancy_type[value] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "RDS Engine validation" do
    let(:engine_type) { Pangea::Resources::Types::RdsEngine }
    
    it "accepts valid RDS engines" do
      valid_engines = ['mysql', 'postgres', 'mariadb', 'aurora-mysql', 'aurora-postgresql']
      valid_engines.each do |engine|
        expect { engine_type[engine] }.not_to raise_error
        expect(engine_type[engine]).to eq(engine)
      end
    end
    
    it "rejects invalid RDS engines" do
      invalid_engines = ['mongodb', 'redis', 'invalid-db', '', nil]
      invalid_engines.each do |engine|
        expect { engine_type[engine] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "S3 Versioning validation" do
    let(:versioning_type) { Pangea::Resources::Types::S3Versioning }
    
    it "accepts valid versioning values" do
      valid_values = ['Enabled', 'Suspended', 'Disabled']
      valid_values.each do |value|
        expect { versioning_type[value] }.not_to raise_error
        expect(versioning_type[value]).to eq(value)
      end
    end
    
    it "rejects invalid versioning values" do
      invalid_values = ['enabled', 'true', 'false', '', nil]
      invalid_values.each do |value|
        expect { versioning_type[value] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end

  describe "Load Balancer Type validation" do
    let(:lb_type) { Pangea::Resources::Types::LoadBalancerType }
    
    it "accepts valid load balancer types" do
      valid_types = ['application', 'network', 'gateway']
      valid_types.each do |type|
        expect { lb_type[type] }.not_to raise_error
        expect(lb_type[type]).to eq(type)
      end
    end
    
    it "rejects invalid load balancer types" do
      invalid_types = ['classic', 'http', 'tcp', '', nil]
      invalid_types.each do |type|
        expect { lb_type[type] }.to raise_error(Dry::Types::ConstraintError)
      end
    end
  end
end