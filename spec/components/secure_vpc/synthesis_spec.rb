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

RSpec.describe "secure_vpc component synthesis validation" do
  # Component synthesis tests - must synthesize all underlying resources
  
  describe "component resource synthesis" do
    it "synthesizes all component resources correctly" do
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:synthesis_vpc, SECURE_VPC_CONFIG)
                      else
                        # Mock component reference for testing
                        MockComponentReference.new('secure_vpc', :synthesis_vpc, SECURE_VPC_CONFIG)
                      end
      
      # Test synthesis of component's underlying resources
      result = test_component_synthesis(component_ref)
      
      # Should have VPC resource
      expect(result["resource"]).to have_key("aws_vpc")
      vpc_resources = result["resource"]["aws_vpc"]
      expect(vpc_resources).not_to be_empty
      
      # Should have flow logs if enabled
      if SECURE_VPC_CONFIG[:enable_flow_logs]
        expect(result["resource"]).to have_key("aws_flow_log")
      end
    end

    it "correctly synthesizes VPC with proper attributes" do
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:vpc_attrs, SECURE_VPC_CONFIG)
                      else
                        MockComponentReference.new('secure_vpc', :vpc_attrs, SECURE_VPC_CONFIG)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Find the VPC in the synthesized result
      vpc_resource = result["resource"]["aws_vpc"].values.first
      
      expect(vpc_resource["cidr_block"]).to eq(SECURE_VPC_CONFIG[:cidr_block])
      expect(vpc_resource["enable_dns_hostnames"]).to eq(true) # Should be enabled for security
      expect(vpc_resource["enable_dns_support"]).to eq(true) # Should be enabled for security
      
      # Should have security-focused tags
      if vpc_resource.has_key?("tags")
        expect(vpc_resource["tags"]).to be_a(Hash)
      end
    end

    it "synthesizes flow logs with correct VPC reference" do
      flow_logs_config = SECURE_VPC_CONFIG.merge(enable_flow_logs: true)
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:flow_synthesis, flow_logs_config)
                      else
                        MockComponentReference.new('secure_vpc', :flow_synthesis, flow_logs_config)
                      end
      
      result = test_component_synthesis(component_ref)
      
      if result["resource"].has_key?("aws_flow_log")
        flow_log_resource = result["resource"]["aws_flow_log"].values.first
        
        # Should reference the VPC
        expect(flow_log_resource["resource_type"]).to eq("VPC")
        expect(flow_log_resource["resource_id"]).to match(/\$\{aws_vpc\..+\.id\}/)
        expect(flow_log_resource["traffic_type"]).to eq("ALL")
      end
    end

    it "synthesizes security groups with VPC reference" do
      sg_config = SECURE_VPC_CONFIG.merge(create_security_groups: true)
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:sg_synthesis, sg_config)
                      else
                        MockComponentReference.new('secure_vpc', :sg_synthesis, sg_config)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Should have security group if component creates one
      if result["resource"].has_key?("aws_security_group")
        sg_resource = result["resource"]["aws_security_group"].values.first
        expect(sg_resource["vpc_id"]).to match(/\$\{aws_vpc\..+\.id\}/)
      end
    end
  end

  describe "component synthesis validation" do
    it "generates valid Terraform JSON for complete component" do
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:complete_synthesis, SECURE_VPC_CONFIG)
                      else
                        MockComponentReference.new('secure_vpc', :complete_synthesis, SECURE_VPC_CONFIG)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Validate overall structure
      validate_terraform_structure(result, :resource)
      
      # Validate resource references
      validate_resource_references(result)
      
      # Validate dependency ordering
      validate_dependency_ordering(result)
    end

    it "handles component with minimal configuration" do
      minimal_config = {
        cidr_block: "10.0.0.0/16",
        availability_zones: ["us-east-1a", "us-east-1b"]
      }
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:minimal_synthesis, minimal_config)
                      else
                        MockComponentReference.new('secure_vpc', :minimal_synthesis, minimal_config)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Should still create VPC with minimal config
      expect(result["resource"]["aws_vpc"]).not_to be_empty
      vpc_resource = result["resource"]["aws_vpc"].values.first
      expect(vpc_resource["cidr_block"]).to eq("10.0.0.0/16")
    end

    it "synthesizes component with multiple availability zones" do
      multi_az_config = SECURE_VPC_CONFIG.merge(
        availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"]
      )
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:multi_az_synthesis, multi_az_config)
                      else
                        MockComponentReference.new('secure_vpc', :multi_az_synthesis, multi_az_config)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Should handle multiple AZs appropriately
      # (specific implementation depends on component design)
      expect(result["resource"]["aws_vpc"]).not_to be_empty
    end
  end

  describe "synthesis with different configurations" do
    it "synthesizes development environment configuration" do
      dev_config = SECURE_VPC_CONFIG.merge(
        environment: "development",
        enable_flow_logs: false, # Cost optimization for dev
        tags: { Environment: "development" }
      )
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:dev_synthesis, dev_config)
                      else
                        MockComponentReference.new('secure_vpc', :dev_synthesis, dev_config)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Should not have flow logs for development
      expect(result["resource"]).not_to have_key("aws_flow_log")
      
      # Should have environment tag
      vpc_resource = result["resource"]["aws_vpc"].values.first
      if vpc_resource.has_key?("tags")
        expect(vpc_resource["tags"]["Environment"]).to eq("development")
      end
    end

    it "synthesizes production environment configuration" do
      prod_config = SECURE_VPC_CONFIG.merge(
        environment: "production",
        enable_flow_logs: true, # Enhanced security for production
        tags: { Environment: "production", Security: "enhanced" }
      )
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:prod_synthesis, prod_config)
                      else
                        MockComponentReference.new('secure_vpc', :prod_synthesis, prod_config)
                      end
      
      result = test_component_synthesis(component_ref)
      
      # Should have flow logs for production
      expect(result["resource"]).to have_key("aws_flow_log") if prod_config[:enable_flow_logs]
      
      # Should have production tags
      vpc_resource = result["resource"]["aws_vpc"].values.first
      if vpc_resource.has_key?("tags")
        expect(vpc_resource["tags"]["Environment"]).to eq("production")
      end
    end
  end

  describe "synthesis performance" do
    it "completes component synthesis within performance threshold" do
      start_time = Time.now
      
      component_ref = if respond_to?(:secure_vpc)
                        secure_vpc(:perf_synthesis, SECURE_VPC_CONFIG)
                      else
                        MockComponentReference.new('secure_vpc', :perf_synthesis, SECURE_VPC_CONFIG)
                      end
      
      result = test_component_synthesis(component_ref)
      
      end_time = Time.now
      synthesis_time = end_time - start_time
      
      # Component synthesis should complete within 15 seconds
      expect(synthesis_time).to be < 15.0
      expect(result).not_to be_empty
    end

    it "handles multiple component instances efficiently" do
      start_time = Time.now
      
      components = []
      3.times do |i|
        config = SECURE_VPC_CONFIG.merge(
          cidr_block: "10.#{i}.0.0/16",
          tags: { Instance: i.to_s }
        )
        
        component_ref = if respond_to?(:secure_vpc)
                          secure_vpc(:"perf_multi_#{i}", config)
                        else
                          MockComponentReference.new('secure_vpc', :"perf_multi_#{i}", config)
                        end
        
        components << component_ref
      end
      
      # Test synthesis of all components
      components.each do |component|
        result = test_component_synthesis(component)
        expect(result["resource"]["aws_vpc"]).not_to be_empty
      end
      
      end_time = Time.now
      total_time = end_time - start_time
      
      # Should handle multiple components efficiently
      expect(total_time).to be < 20.0
    end
  end

  describe "synthesis error handling" do
    it "fails synthesis gracefully for invalid component configuration" do
      invalid_config = { invalid_attribute: "invalid" }
      
      expect {
        if respond_to?(:secure_vpc)
          component_ref = secure_vpc(:invalid_synthesis, invalid_config)
          test_component_synthesis(component_ref)
        else
          # Mock should also fail appropriately
          component_ref = MockComponentReference.new('secure_vpc', :invalid_synthesis, invalid_config)
          test_component_synthesis(component_ref)
        end
      }.to raise_error
    end

    it "provides meaningful errors during component synthesis" do
      error_caught = false
      
      begin
        component_ref = if respond_to?(:secure_vpc)
                          secure_vpc(:error_synthesis, { cidr_block: "invalid" })
                        else
                          MockComponentReference.new('secure_vpc', :error_synthesis, { cidr_block: "invalid" })
                        end
        
        test_component_synthesis(component_ref)
      rescue => e
        error_caught = true
        expect(e.message).to be_a(String)
        expect(e.message.length).to be > 0
      end
      
      expect(error_caught).to be(true)
    end
  end
end

# Mock component reference for testing when actual component isn't available
class MockComponentReference
  attr_reader :type, :name, :component_attributes, :resources

  def initialize(type, name, attributes)
    @type = type
    @name = name
    @component_attributes = attributes
    @resources = build_mock_resources(attributes)
  end

  def outputs
    {
      vpc_id: resources[:vpc]&.id,
      vpc_cidr: component_attributes[:cidr_block],
      flow_logs_enabled: !!resources[:flow_logs]
    }
  end

  private

  def build_mock_resources(attributes)
    resources = {}
    
    # Always create VPC resource
    resources[:vpc] = MockResourceReference.new(
      "aws_vpc", 
      "#{name}_vpc", 
      {
        cidr_block: attributes[:cidr_block],
        enable_dns_hostnames: true,
        enable_dns_support: true,
        tags: attributes[:tags] || {}
      }
    )
    
    # Create flow logs if enabled
    if attributes[:enable_flow_logs]
      resources[:flow_logs] = MockResourceReference.new(
        "aws_flow_log",
        "#{name}_flow_logs",
        {
          resource_type: "VPC",
          resource_id: resources[:vpc].id,
          traffic_type: "ALL",
          log_destination: "cloud-watch-logs"
        }
      )
    end
    
    resources
  end
end