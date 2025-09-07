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

# Load aws_eip resource and types for testing
require 'pangea/resources/aws_eip/resource'
require 'pangea/resources/aws_eip/types'

RSpec.describe "aws_eip resource function" do
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
  
  describe "EipAttributes validation" do
    it "accepts minimal configuration with default VPC domain" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({})
      
      expect(attrs.domain).to eq('vpc')
      expect(attrs.tags).to eq({})
      expect(attrs.vpc?).to eq(true)
      expect(attrs.associated?).to eq(false)
      expect(attrs.customer_owned?).to eq(false)
      expect(attrs.association_type).to eq(:unassociated)
    end
    
    it "accepts domain specification" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        domain: "standard"
      })
      
      expect(attrs.domain).to eq("standard")
      expect(attrs.vpc?).to eq(false)
    end
    
    it "accepts instance association" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        instance: "i-1234567890abcdef0"
      })
      
      expect(attrs.instance).to eq("i-1234567890abcdef0")
      expect(attrs.associated?).to eq(true)
      expect(attrs.association_type).to eq(:instance)
    end
    
    it "accepts network interface association" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        network_interface: "eni-1234567890abcdef0"
      })
      
      expect(attrs.network_interface).to eq("eni-1234567890abcdef0")
      expect(attrs.associated?).to eq(true)
      expect(attrs.association_type).to eq(:network_interface)
    end
    
    it "validates instance and network_interface are mutually exclusive" do
      expect {
        Pangea::Resources::AWS::EipAttributes.new({
          instance: "i-1234567890abcdef0",
          network_interface: "eni-1234567890abcdef0"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'instance' and 'network_interface'/)
    end
    
    it "accepts private IP association with network interface" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        network_interface: "eni-1234567890abcdef0",
        associate_with_private_ip: "10.0.1.50"
      })
      
      expect(attrs.associate_with_private_ip).to eq("10.0.1.50")
    end
    
    it "validates private IP requires network interface" do
      expect {
        Pangea::Resources::AWS::EipAttributes.new({
          associate_with_private_ip: "10.0.1.50"
        })
      }.to raise_error(Dry::Struct::Error, /'associate_with_private_ip' requires 'network_interface'/)
    end
    
    it "accepts customer-owned IP pool" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        customer_owned_ipv4_pool: "ipv4pool-coip-12345678"
      })
      
      expect(attrs.customer_owned_ipv4_pool).to eq("ipv4pool-coip-12345678")
      expect(attrs.customer_owned?).to eq(true)
    end
    
    it "accepts public IPv4 pool" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        public_ipv4_pool: "amazon"
      })
      
      expect(attrs.public_ipv4_pool).to eq("amazon")
    end
    
    it "validates customer and public pools are mutually exclusive" do
      expect {
        Pangea::Resources::AWS::EipAttributes.new({
          customer_owned_ipv4_pool: "ipv4pool-coip-12345678",
          public_ipv4_pool: "amazon"
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'customer_owned_ipv4_pool' and 'public_ipv4_pool'/)
    end
    
    it "accepts network border group" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        network_border_group: "us-east-1-wl1-bos-wlz-1"
      })
      
      expect(attrs.network_border_group).to eq("us-east-1-wl1-bos-wlz-1")
    end
    
    it "accepts tags" do
      attrs = Pangea::Resources::AWS::EipAttributes.new({
        tags: {
          Name: "web-server-eip",
          Environment: "production",
          Application: "web-app"
        }
      })
      
      expect(attrs.tags[:Name]).to eq("web-server-eip")
      expect(attrs.tags[:Environment]).to eq("production")
      expect(attrs.tags[:Application]).to eq("web-app")
    end
  end
  
  describe "aws_eip function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_eip(:test, {})
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_eip')
      expect(ref.name).to eq(:test)
    end
    
    it "creates an EIP with default VPC domain" do
      ref = test_instance.aws_eip(:web_ip, {})
      
      attrs = ref.resource_attributes
      expect(attrs[:domain]).to eq("vpc")
      expect(ref.vpc?).to eq(true)
    end
    
    it "creates an EIP for EC2-Classic" do
      ref = test_instance.aws_eip(:classic_ip, {
        domain: "standard"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:domain]).to eq("standard")
      expect(ref.vpc?).to eq(false)
    end
    
    it "creates an EIP associated with an instance" do
      ref = test_instance.aws_eip(:instance_eip, {
        instance: "i-1234567890abcdef0",
        tags: { Name: "instance-eip" }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:instance]).to eq("i-1234567890abcdef0")
      expect(ref.associated?).to eq(true)
      expect(ref.association_type).to eq(:instance)
    end
    
    it "creates an EIP associated with a network interface" do
      ref = test_instance.aws_eip(:eni_eip, {
        network_interface: "eni-1234567890abcdef0",
        tags: { Name: "eni-eip" }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:network_interface]).to eq("eni-1234567890abcdef0")
      expect(ref.associated?).to eq(true)
      expect(ref.association_type).to eq(:network_interface)
    end
    
    it "creates an EIP with private IP association" do
      ref = test_instance.aws_eip(:private_ip_eip, {
        network_interface: "eni-1234567890abcdef0",
        associate_with_private_ip: "10.0.1.50"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:network_interface]).to eq("eni-1234567890abcdef0")
      expect(attrs[:associate_with_private_ip]).to eq("10.0.1.50")
    end
    
    it "creates an unassociated EIP for later use" do
      ref = test_instance.aws_eip(:reserved_ip, {
        tags: {
          Name: "reserved-ip",
          Status: "unassigned",
          Purpose: "future-use"
        }
      })
      
      expect(ref.associated?).to eq(false)
      expect(ref.association_type).to eq(:unassociated)
      expect(ref.resource_attributes[:tags][:Status]).to eq("unassigned")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_eip(:test, {})
      
      expected_outputs = [
        :id, :allocation_id, :association_id, :carrier_ip, :customer_owned_ip,
        :customer_owned_ipv4_pool, :domain, :instance, :network_border_group,
        :network_interface, :private_dns, :private_ip, :public_dns, :public_ip,
        :public_ipv4_pool, :tags_all, :vpc
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_eip.test.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_eip(:test, {
        instance: "i-1234567890abcdef0"
      })
      
      expect(ref.vpc?).to eq(true)
      expect(ref.associated?).to eq(true)
      expect(ref.customer_owned?).to eq(false)
      expect(ref.association_type).to eq(:instance)
    end
  end
  
  describe "common EIP patterns" do
    it "creates an EIP for a NAT gateway" do
      ref = test_instance.aws_eip(:nat_eip, {
        domain: "vpc",
        tags: {
          Name: "nat-gateway-eip",
          Purpose: "nat-gateway",
          Environment: "production"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:domain]).to eq("vpc")
      expect(attrs[:tags][:Purpose]).to eq("nat-gateway")
      expect(ref.associated?).to eq(false)  # NAT gateway association happens separately
    end
    
    it "creates an EIP pool for auto-scaling" do
      eip_pool = (1..3).map do |i|
        test_instance.aws_eip(:"pool_#{i}", {
          domain: "vpc",
          tags: {
            Name: "eip-pool-#{i}",
            Pool: "web-servers",
            Index: i.to_s
          }
        })
      end
      
      expect(eip_pool.length).to eq(3)
      expect(eip_pool.all? { |eip| eip.type == 'aws_eip' }).to eq(true)
      expect(eip_pool.all? { |eip| !eip.associated? }).to eq(true)
    end
    
    it "creates an EIP with customer-owned IP for Outposts" do
      ref = test_instance.aws_eip(:outpost_eip, {
        domain: "vpc",
        customer_owned_ipv4_pool: "ipv4pool-coip-12345678",
        tags: {
          Name: "outpost-eip",
          Location: "on-premises"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:customer_owned_ipv4_pool]).to eq("ipv4pool-coip-12345678")
      expect(ref.customer_owned?).to eq(true)
    end
    
    it "creates an EIP with network border group for Wavelength" do
      ref = test_instance.aws_eip(:wavelength_eip, {
        domain: "vpc",
        network_border_group: "us-east-1-wl1-bos-wlz-1",
        tags: {
          Name: "wavelength-eip",
          Type: "edge-compute"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:network_border_group]).to eq("us-east-1-wl1-bos-wlz-1")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_eip(:test_eip, {})
      
      expect(ref.outputs[:id]).to eq("${aws_eip.test_eip.id}")
      expect(ref.outputs[:allocation_id]).to eq("${aws_eip.test_eip.allocation_id}")
      expect(ref.outputs[:public_ip]).to eq("${aws_eip.test_eip.public_ip}")
      expect(ref.outputs[:private_ip]).to eq("${aws_eip.test_eip.private_ip}")
    end
    
    it "can be used with other AWS resources" do
      eip_ref = test_instance.aws_eip(:app_eip, {
        domain: "vpc",
        tags: { Name: "application-eip" }
      })
      
      # Simulate using EIP reference with instance
      allocation_id = eip_ref.outputs[:allocation_id]
      public_ip = eip_ref.outputs[:public_ip]
      
      expect(allocation_id).to eq("${aws_eip.app_eip.allocation_id}")
      expect(public_ip).to eq("${aws_eip.app_eip.public_ip}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_eip(:cross_ref, {
        instance: "${aws_instance.web.id}",
        tags: {
          Name: "${var.application}-eip",
          Environment: "${var.environment}",
          Instance: "${aws_instance.web.id}"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:instance]).to include("aws_instance.web.id")
      expect(attrs[:tags][:Name]).to include("var.application")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles default values correctly" do
      ref = test_instance.aws_eip(:defaults, {})
      
      attrs = ref.resource_attributes
      expect(attrs[:domain]).to eq("vpc")
      expect(attrs[:tags]).to eq({})
      expect(attrs[:instance]).to be_nil
      expect(attrs[:network_interface]).to be_nil
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_eip(:string_keys, {
        "domain" => "vpc",
        "instance" => "i-1234567890abcdef0",
        "tags" => {
          Name: "string-key-eip"
        }
      })
      
      expect(ref.resource_attributes[:domain]).to eq("vpc")
      expect(ref.resource_attributes[:instance]).to eq("i-1234567890abcdef0")
      expect(ref.resource_attributes[:tags][:Name]).to eq("string-key-eip")
    end
    
    it "correctly identifies association types" do
      unassoc = test_instance.aws_eip(:unassoc, {})
      instance_assoc = test_instance.aws_eip(:inst, { instance: "i-123" })
      eni_assoc = test_instance.aws_eip(:eni, { network_interface: "eni-123" })
      
      expect(unassoc.association_type).to eq(:unassociated)
      expect(instance_assoc.association_type).to eq(:instance)
      expect(eni_assoc.association_type).to eq(:network_interface)
    end
    
    it "handles VPC vs standard domain detection" do
      vpc_eip = test_instance.aws_eip(:vpc_test, { domain: "vpc" })
      standard_eip = test_instance.aws_eip(:standard_test, { domain: "standard" })
      default_eip = test_instance.aws_eip(:default_test, {})
      
      expect(vpc_eip.vpc?).to eq(true)
      expect(standard_eip.vpc?).to eq(false)
      expect(default_eip.vpc?).to eq(true)  # Default is VPC
    end
  end
end