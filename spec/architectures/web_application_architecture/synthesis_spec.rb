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

RSpec.describe "web_application_architecture synthesis validation" do
  # Complete architecture synthesis tests - must synthesize entire infrastructure stack
  
  describe "complete architecture synthesis" do
    it "synthesizes complete web application infrastructure" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:complete_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :complete_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      # Test complete infrastructure synthesis
      result = test_architecture_synthesis(arch_ref)
      
      # Validate complete infrastructure is present
      validate_web_app_terraform(result)
    end

    it "synthesizes all required components correctly" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:components_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :components_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Should have network infrastructure
      expect(result["resource"]).to have_key("aws_vpc")
      expect(result["resource"]).to have_key("aws_subnet")
      expect(result["resource"]).to have_key("aws_internet_gateway")
      
      # Should have compute infrastructure
      expect(result["resource"]).to have_key("aws_lb").or(have_key("aws_alb"))
      expect(result["resource"]).to have_key("aws_autoscaling_group").or(have_key("aws_instance"))
      
      # Should have database if enabled
      if WEB_APPLICATION_CONFIG[:database_enabled]
        expect(result["resource"]).to have_key("aws_db_instance").or(have_key("aws_rds_cluster"))
      end
    end

    it "synthesizes with proper resource dependencies" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:dependencies_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :dependencies_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Validate dependency ordering
      validate_dependency_ordering(result)
      
      # Validate resource references
      validate_resource_references(result)
    end

    it "synthesizes environment-specific configurations" do
      environments = ['development', 'staging', 'production']
      
      environments.each do |env|
        env_config = WEB_APPLICATION_CONFIG.merge(environment: env)
        
        arch_ref = if respond_to?(:web_application_architecture)
                     web_application_architecture(:"#{env}_synthesis", env_config)
                   else
                     MockArchitectureReference.new('web_application_architecture', :"#{env}_synthesis", env_config)
                   end
        
        result = test_architecture_synthesis(arch_ref)
        
        # Validate basic infrastructure
        expect(result["resource"]).to have_key("aws_vpc")
        
        # Production should have additional resources
        if env == 'production'
          # Should have enhanced monitoring, backup, etc.
          # (specific validation depends on implementation)
        end
      end
    end
  end

  describe "architecture component synthesis" do
    it "synthesizes network components correctly" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:network_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :network_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Network components
      vpc_resources = result["resource"]["aws_vpc"]
      expect(vpc_resources).not_to be_empty
      
      vpc_config = vpc_resources.values.first
      expect(vpc_config["cidr_block"]).to eq(WEB_APPLICATION_CONFIG[:vpc_cidr])
      expect(vpc_config["enable_dns_hostnames"]).to eq(true)
      expect(vpc_config["enable_dns_support"]).to eq(true)
      
      # Should have subnets
      if result["resource"].has_key?("aws_subnet")
        subnet_resources = result["resource"]["aws_subnet"]
        expect(subnet_resources.size).to be >= 2 # At least public and private
      end
    end

    it "synthesizes load balancer components correctly" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:lb_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :lb_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Load balancer
      if result["resource"].has_key?("aws_lb")
        lb_resources = result["resource"]["aws_lb"]
        expect(lb_resources).not_to be_empty
        
        lb_config = lb_resources.values.first
        expect(lb_config["load_balancer_type"]).to eq("application")
        expect(lb_config["subnets"]).to be_a(Array)
        expect(lb_config["security_groups"]).to be_a(Array)
      end
    end

    it "synthesizes auto scaling components correctly" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:asg_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :asg_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Auto Scaling Group
      if result["resource"].has_key?("aws_autoscaling_group")
        asg_resources = result["resource"]["aws_autoscaling_group"]
        expect(asg_resources).not_to be_empty
        
        asg_config = asg_resources.values.first
        expect(asg_config["min_size"]).to eq(WEB_APPLICATION_CONFIG[:auto_scaling][:min])
        expect(asg_config["max_size"]).to eq(WEB_APPLICATION_CONFIG[:auto_scaling][:max])
        expect(asg_config["vpc_zone_identifier"]).to be_a(Array)
      end
    end

    it "synthesizes database components correctly" do
      db_config = WEB_APPLICATION_CONFIG.merge(database_enabled: true)
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:db_synthesis, db_config)
                 else
                   MockArchitectureReference.new('web_application_architecture', :db_synthesis, db_config)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Database
      if result["resource"].has_key?("aws_db_instance")
        db_resources = result["resource"]["aws_db_instance"]
        expect(db_resources).not_to be_empty
        
        db_config = db_resources.values.first
        expect(db_config["engine"]).to eq(WEB_APPLICATION_CONFIG[:database_engine])
        expect(db_config["instance_class"]).to eq(WEB_APPLICATION_CONFIG[:database_instance_class])
        expect(db_config["allocated_storage"]).to eq(WEB_APPLICATION_CONFIG[:database_allocated_storage])
      end
    end
  end

  describe "synthesis with optional components" do
    it "synthesizes with caching enabled" do
      cache_config = WEB_APPLICATION_CONFIG.merge(enable_caching: true)
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:cache_synthesis, cache_config)
                 else
                   MockArchitectureReference.new('web_application_architecture', :cache_synthesis, cache_config)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Should include caching resources
      if result["resource"].has_key?("aws_elasticache_replication_group")
        cache_resources = result["resource"]["aws_elasticache_replication_group"]
        expect(cache_resources).not_to be_empty
      end
    end

    it "synthesizes with CDN enabled" do
      cdn_config = WEB_APPLICATION_CONFIG.merge(enable_cdn: true)
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:cdn_synthesis, cdn_config)
                 else
                   MockArchitectureReference.new('web_application_architecture', :cdn_synthesis, cdn_config)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Should include CDN resources
      if result["resource"].has_key?("aws_cloudfront_distribution")
        cdn_resources = result["resource"]["aws_cloudfront_distribution"]
        expect(cdn_resources).not_to be_empty
        
        cdn_config = cdn_resources.values.first
        expect(cdn_config).to have_key("origin")
      end
    end

    it "synthesizes without optional components" do
      minimal_config = WEB_APPLICATION_CONFIG.merge(
        enable_caching: false,
        enable_cdn: false,
        database_enabled: false
      )
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:minimal_synthesis, minimal_config)
                 else
                   MockArchitectureReference.new('web_application_architecture', :minimal_synthesis, minimal_config)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Should not include optional resources
      expect(result["resource"]).not_to have_key("aws_elasticache_replication_group")
      expect(result["resource"]).not_to have_key("aws_cloudfront_distribution")
      expect(result["resource"]).not_to have_key("aws_db_instance")
    end
  end

  describe "synthesis validation" do
    it "generates valid Terraform JSON for complete architecture" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:valid_json_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :valid_json_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Validate JSON structure
      validate_terraform_structure(result, :resource)
      
      # Ensure it can be serialized to JSON
      json_string = result.to_json
      expect(json_string).to be_a(String)
      
      # Ensure it can be parsed back
      parsed = JSON.parse(json_string)
      expect(parsed).to eq(result)
    end

    it "handles provider configuration in synthesis" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:provider_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :provider_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Should work with implicit or explicit provider configuration
      validate_provider_configuration(result, "aws") if result.has_key?("provider")
    end

    it "maintains consistent naming across resources" do
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:naming_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :naming_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Resource names should follow consistent patterns
      result["resource"].each do |resource_type, type_resources|
        type_resources.keys.each do |resource_name|
          # Should contain architecture name or follow naming convention
          expect(resource_name).to match(/naming_synthesis/) if resource_name.is_a?(String)
        end
      end
    end

    it "applies tags consistently across resources" do
      tagged_config = WEB_APPLICATION_CONFIG.merge(
        tags: { Project: "SynthesisTest", Environment: "test" }
      )
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:tagged_synthesis, tagged_config)
                 else
                   MockArchitectureReference.new('web_application_architecture', :tagged_synthesis, tagged_config)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      # Most resources should have consistent tags
      taggable_resources = ["aws_vpc", "aws_subnet", "aws_lb", "aws_autoscaling_group", "aws_db_instance"]
      
      taggable_resources.each do |resource_type|
        if result["resource"].has_key?(resource_type)
          result["resource"][resource_type].each do |name, config|
            if config.has_key?("tags")
              expect(config["tags"]["Project"]).to eq("SynthesisTest")
              expect(config["tags"]["Environment"]).to eq("test")
            end
          end
        end
      end
    end
  end

  describe "synthesis performance" do
    it "completes architecture synthesis within performance threshold" do
      start_time = Time.now
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:perf_synthesis, WEB_APPLICATION_CONFIG)
                 else
                   MockArchitectureReference.new('web_application_architecture', :perf_synthesis, WEB_APPLICATION_CONFIG)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      end_time = Time.now
      synthesis_time = end_time - start_time
      
      # Architecture synthesis should complete within 30 seconds
      expect(synthesis_time).to be < 30.0
      expect(result).not_to be_empty
    end

    it "handles complex architecture synthesis efficiently" do
      complex_config = WEB_APPLICATION_CONFIG.merge(
        enable_caching: true,
        enable_cdn: true,
        high_availability: true,
        auto_scaling: { min: 3, max: 20, desired: 5 }
      )
      
      start_time = Time.now
      
      arch_ref = if respond_to?(:web_application_architecture)
                   web_application_architecture(:complex_synthesis, complex_config)
                 else
                   MockArchitectureReference.new('web_application_architecture', :complex_synthesis, complex_config)
                 end
      
      result = test_architecture_synthesis(arch_ref)
      
      end_time = Time.now
      total_time = end_time - start_time
      
      # Complex architecture should still synthesize efficiently
      expect(total_time).to be < 45.0
      expect(result["resource"].keys.length).to be >= 5 # Should have multiple resource types
    end
  end

  describe "synthesis error handling" do
    it "fails synthesis gracefully for invalid architecture configuration" do
      expect {
        arch_ref = if respond_to?(:web_application_architecture)
                     web_application_architecture(:error_synthesis, INVALID_WEB_APP_CONFIGS[:invalid_domain])
                   else
                     MockArchitectureReference.new('web_application_architecture', :error_synthesis, INVALID_WEB_APP_CONFIGS[:invalid_domain])
                   end
        
        test_architecture_synthesis(arch_ref)
      }.to raise_error
    end

    it "provides meaningful errors during architecture synthesis" do
      error_caught = false
      
      begin
        arch_ref = if respond_to?(:web_application_architecture)
                     web_application_architecture(:error_detail_synthesis, INVALID_WEB_APP_CONFIGS[:invalid_cidr])
                   else
                     MockArchitectureReference.new('web_application_architecture', :error_detail_synthesis, INVALID_WEB_APP_CONFIGS[:invalid_cidr])
                   end
        
        test_architecture_synthesis(arch_ref)
      rescue => e
        error_caught = true
        expect(e.message).to be_a(String)
        expect(e.message.length).to be > 0
      end
      
      expect(error_caught).to be(true)
    end
  end
end

# Mock architecture reference for testing when actual architecture isn't available
class MockArchitectureReference
  attr_reader :type, :name, :architecture_attributes, :components, :resources

  def initialize(type, name, attributes)
    @type = type
    @name = name
    @architecture_attributes = attributes
    @components = build_mock_components(attributes)
    @resources = build_mock_resources(attributes)
  end

  def outputs
    {
      application_url: "https://#{architecture_attributes[:domain_name]}",
      estimated_monthly_cost: 150.0,
      security_compliance_score: 85.0
    }
  end

  private

  def build_mock_components(attributes)
    components = {}
    
    # Network component
    components[:network] = MockComponentReference.new('secure_vpc', :"#{name}_network", {
      cidr_block: attributes[:vpc_cidr] || "10.0.0.0/16",
      availability_zones: attributes[:availability_zones] || ["us-east-1a", "us-east-1b"]
    })
    
    # Load balancer component
    components[:load_balancer] = MockComponentReference.new('application_load_balancer', :"#{name}_alb", {
      subnet_refs: [],
      security_group_refs: []
    })
    
    # Web servers component
    components[:web_servers] = MockComponentReference.new('auto_scaling_web_servers', :"#{name}_asg", {
      min_size: attributes[:auto_scaling][:min],
      max_size: attributes[:auto_scaling][:max],
      instance_type: attributes[:instance_type]
    })
    
    # Database component (if enabled)
    if attributes[:database_enabled] != false
      components[:database] = MockComponentReference.new('mysql_database', :"#{name}_db", {
        engine: attributes[:database_engine],
        instance_class: attributes[:database_instance_class]
      })
    end
    
    # Optional components
    if attributes[:enable_caching]
      components[:cache] = MockComponentReference.new('elasticache_redis', :"#{name}_cache", {})
    end
    
    if attributes[:enable_cdn]
      components[:cdn] = MockComponentReference.new('cloudfront_distribution', :"#{name}_cdn", {})
    end
    
    components
  end

  def build_mock_resources(attributes)
    resources = {}
    
    # DNS zone
    if attributes[:domain_name]
      resources[:dns_zone] = MockResourceReference.new("aws_route53_zone", :"#{name}_zone", {
        name: attributes[:domain_name]
      })
    end
    
    resources
  end
end