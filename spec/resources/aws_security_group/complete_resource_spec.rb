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

# Load aws_security_group resource and types for testing
require 'pangea/resources/aws_security_group/resource'
require 'pangea/resources/aws_security_group/types'

RSpec.describe "aws_security_group resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  let(:vpc_id) { "${aws_vpc.test.id}" }
  
  describe "SecurityGroup attributes validation" do
    it "accepts minimal security group with no attributes" do
      attrs = Pangea::Resources::AWS::SecurityGroupAttributes.new({})
      
      expect(attrs.name_prefix).to be_nil
      expect(attrs.vpc_id).to be_nil
      expect(attrs.description).to be_nil
      expect(attrs.ingress_rules).to eq([])
      expect(attrs.egress_rules).to eq([])
      expect(attrs.tags).to eq({})
    end
    
    it "accepts security group with basic attributes" do
      attrs = Pangea::Resources::AWS::SecurityGroupAttributes.new({
        name_prefix: "web-sg-",
        vpc_id: vpc_id,
        description: "Web server security group"
      })
      
      expect(attrs.name_prefix).to eq("web-sg-")
      expect(attrs.vpc_id).to eq(vpc_id)
      expect(attrs.description).to eq("Web server security group")
    end
    
    it "accepts security group with ingress rules" do
      ingress_rules = [
        {
          from_port: 80,
          to_port: 80,
          protocol: "tcp",
          cidr_blocks: ["0.0.0.0/0"]
        },
        {
          from_port: 443,
          to_port: 443,
          protocol: "tcp",
          cidr_blocks: ["0.0.0.0/0"]
        }
      ]
      
      attrs = Pangea::Resources::AWS::SecurityGroupAttributes.new({
        vpc_id: vpc_id,
        ingress_rules: ingress_rules
      })
      
      # The dry-struct adds default security_groups: [] to each rule
      expected_rules = ingress_rules.map { |rule| rule.merge(security_groups: []) }
      expect(attrs.ingress_rules).to eq(expected_rules)
    end
    
    it "accepts security group with egress rules" do
      egress_rules = [
        {
          from_port: 0,
          to_port: 65535,
          protocol: "-1",
          cidr_blocks: ["0.0.0.0/0"]
        }
      ]
      
      attrs = Pangea::Resources::AWS::SecurityGroupAttributes.new({
        vpc_id: vpc_id,
        egress_rules: egress_rules
      })
      
      # The dry-struct adds default security_groups: [] to each rule
      expected_rules = egress_rules.map { |rule| rule.merge(security_groups: []) }
      expect(attrs.egress_rules).to eq(expected_rules)
    end
    
    it "accepts security group with tags" do
      attrs = Pangea::Resources::AWS::SecurityGroupAttributes.new({
        vpc_id: vpc_id,
        tags: { Name: "test-security-group", Environment: "test" }
      })
      
      expect(attrs.tags).to eq({
        Name: "test-security-group",
        Environment: "test"
      })
    end
    
    describe "ingress rule validation" do
      it "validates required fields in ingress rules" do
        expect {
          Pangea::Resources::AWS::SecurityGroupAttributes.new({
            vpc_id: vpc_id,
            ingress_rules: [
              {
                from_port: 80,
                to_port: 80
                # Missing protocol
              }
            ]
          })
        }.to raise_error(Dry::Struct::Error, /missing required fields/)
      end
      
      it "validates port range in ingress rules" do
        expect {
          Pangea::Resources::AWS::SecurityGroupAttributes.new({
            vpc_id: vpc_id,
            ingress_rules: [
              {
                from_port: 8080,
                to_port: 80,  # Invalid: from_port > to_port
                protocol: "tcp"
              }
            ]
          })
        }.to raise_error(Dry::Struct::Error, /from_port.*cannot be greater than to_port/)
      end
      
      it "validates protocol in ingress rules" do
        expect {
          Pangea::Resources::AWS::SecurityGroupAttributes.new({
            vpc_id: vpc_id,
            ingress_rules: [
              {
                from_port: 80,
                to_port: 80,
                protocol: "invalid-protocol"
              }
            ]
          })
        }.to raise_error(Dry::Struct::Error, /protocol.*is not valid/)
      end
      
      it "validates CIDR blocks in ingress rules" do
        expect {
          Pangea::Resources::AWS::SecurityGroupAttributes.new({
            vpc_id: vpc_id,
            ingress_rules: [
              {
                from_port: 80,
                to_port: 80,
                protocol: "tcp",
                cidr_blocks: ["invalid-cidr"]
              }
            ]
          })
        }.to raise_error(Dry::Struct::Error, /invalid CIDR block/)
      end
      
      it "accepts valid ingress rule protocols" do
        valid_protocols = %w[tcp udp icmp icmpv6 -1]
        
        valid_protocols.each do |protocol|
          expect {
            Pangea::Resources::AWS::SecurityGroupAttributes.new({
              vpc_id: vpc_id,
              ingress_rules: [
                {
                  from_port: 80,
                  to_port: 80,
                  protocol: protocol,
                  cidr_blocks: ["10.0.0.0/16"]
                }
              ]
            })
          }.not_to raise_error
        end
      end
    end
    
    describe "egress rule validation" do
      it "validates required fields in egress rules" do
        expect {
          Pangea::Resources::AWS::SecurityGroupAttributes.new({
            vpc_id: vpc_id,
            egress_rules: [
              {
                from_port: 80
                # Missing to_port and protocol
              }
            ]
          })
        }.to raise_error(Dry::Struct::Error, /missing required fields/)
      end
      
      it "validates port range in egress rules" do
        expect {
          Pangea::Resources::AWS::SecurityGroupAttributes.new({
            vpc_id: vpc_id,
            egress_rules: [
              {
                from_port: 8080,
                to_port: 80,  # Invalid: from_port > to_port
                protocol: "tcp"
              }
            ]
          })
        }.to raise_error(Dry::Struct::Error, /from_port.*cannot be greater than to_port/)
      end
    end
  end
  
  describe "aws_security_group function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_security_group(:test, {})
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_security_group')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with basic attributes" do
      ref = test_instance.aws_security_group(:web, {
        name_prefix: "web-sg-",
        vpc_id: vpc_id,
        description: "Web server security group"
      })
      
      expect(ref.resource_attributes[:name_prefix]).to eq("web-sg-")
      expect(ref.resource_attributes[:vpc_id]).to eq(vpc_id)
      expect(ref.resource_attributes[:description]).to eq("Web server security group")
    end
    
    it "handles ingress rules correctly" do
      ingress_rules = [
        {
          from_port: 80,
          to_port: 80,
          protocol: "tcp",
          cidr_blocks: ["0.0.0.0/0"]
        }
      ]
      
      ref = test_instance.aws_security_group(:web, {
        vpc_id: vpc_id,
        ingress_rules: ingress_rules
      })
      
      # The dry-struct adds default security_groups: [] to each rule
      expected_rules = ingress_rules.map { |rule| rule.merge(security_groups: []) }
      expect(ref.resource_attributes[:ingress_rules]).to eq(expected_rules)
    end
    
    it "handles egress rules correctly" do
      egress_rules = [
        {
          from_port: 0,
          to_port: 65535,
          protocol: "-1",
          cidr_blocks: ["0.0.0.0/0"]
        }
      ]
      
      ref = test_instance.aws_security_group(:all_outbound, {
        vpc_id: vpc_id,
        egress_rules: egress_rules
      })
      
      # The dry-struct adds default security_groups: [] to each rule
      expected_rules = egress_rules.map { |rule| rule.merge(security_groups: []) }
      expect(ref.resource_attributes[:egress_rules]).to eq(expected_rules)
    end
    
    it "handles tags correctly" do
      ref = test_instance.aws_security_group(:tagged, {
        vpc_id: vpc_id,
        tags: { Name: "test-sg", Environment: "testing" }
      })
      
      expect(ref.resource_attributes[:tags]).to eq({
        Name: "test-sg",
        Environment: "testing"
      })
    end
    
    it "validates ingress rules in function call" do
      expect {
        test_instance.aws_security_group(:invalid, {
          vpc_id: vpc_id,
          ingress_rules: [
            {
              from_port: 80,
              # Missing to_port and protocol
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /missing required fields/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_security_group(:test, { vpc_id: vpc_id })
      
      expected_outputs = [:id, :arn, :vpc_id, :owner_id, :name]
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_security_group.test.#{output}}")
      end
    end
  end
  
  describe "common security group patterns" do
    it "creates a web server security group" do
      ref = test_instance.aws_security_group(:web, {
        name_prefix: "web-",
        vpc_id: vpc_id,
        description: "Web server security group",
        ingress_rules: [
          {
            from_port: 80,
            to_port: 80,
            protocol: "tcp",
            cidr_blocks: ["0.0.0.0/0"]
          },
          {
            from_port: 443,
            to_port: 443,
            protocol: "tcp",
            cidr_blocks: ["0.0.0.0/0"]
          }
        ],
        egress_rules: [
          {
            from_port: 0,
            to_port: 65535,
            protocol: "-1",
            cidr_blocks: ["0.0.0.0/0"]
          }
        ],
        tags: { Name: "web-server-sg", Purpose: "web" }
      })
      
      expect(ref.resource_attributes[:description]).to eq("Web server security group")
      expect(ref.resource_attributes[:ingress_rules].length).to eq(2)
      expect(ref.resource_attributes[:egress_rules].length).to eq(1)
    end
    
    it "creates a database security group" do
      ref = test_instance.aws_security_group(:database, {
        name_prefix: "db-",
        vpc_id: vpc_id,
        description: "Database security group",
        ingress_rules: [
          {
            from_port: 3306,
            to_port: 3306,
            protocol: "tcp",
            cidr_blocks: ["10.0.0.0/16"]  # VPC CIDR only
          }
        ],
        tags: { Name: "database-sg", Purpose: "database" }
      })
      
      expect(ref.resource_attributes[:description]).to eq("Database security group")
      expect(ref.resource_attributes[:ingress_rules].first[:from_port]).to eq(3306)
      expect(ref.resource_attributes[:ingress_rules].first[:cidr_blocks]).to eq(["10.0.0.0/16"])
    end
    
    it "creates an SSH access security group" do
      ref = test_instance.aws_security_group(:ssh, {
        name_prefix: "ssh-",
        vpc_id: vpc_id,
        description: "SSH access security group",
        ingress_rules: [
          {
            from_port: 22,
            to_port: 22,
            protocol: "tcp",
            cidr_blocks: ["203.0.113.0/24"]  # Specific office IP range
          }
        ],
        tags: { Name: "ssh-access-sg", Purpose: "ssh" }
      })
      
      expect(ref.resource_attributes[:ingress_rules].first[:from_port]).to eq(22)
      expect(ref.resource_attributes[:ingress_rules].first[:protocol]).to eq("tcp")
    end
    
    it "creates a security group with ICMP rules" do
      ref = test_instance.aws_security_group(:icmp, {
        vpc_id: vpc_id,
        description: "ICMP ping security group",
        ingress_rules: [
          {
            from_port: 8,   # ICMP type 8 (echo request - ping)
            to_port: 8,     # Same as from_port for ICMP type
            protocol: "icmp",
            cidr_blocks: ["10.0.0.0/16"]
          }
        ]
      })
      
      expect(ref.resource_attributes[:ingress_rules].first[:protocol]).to eq("icmp")
      expect(ref.resource_attributes[:ingress_rules].first[:from_port]).to eq(8)
    end
    
    it "creates a security group with no rules" do
      ref = test_instance.aws_security_group(:empty, {
        name_prefix: "empty-sg-",
        vpc_id: vpc_id,
        description: "Empty security group for testing"
      })
      
      expect(ref.resource_attributes[:ingress_rules]).to eq([])
      expect(ref.resource_attributes[:egress_rules]).to eq([])
      expect(ref.resource_attributes[:description]).to eq("Empty security group for testing")
    end
  end
end