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

# Load aws_lb resource and types for testing
require 'pangea/resources/aws_lb/resource'
require 'pangea/resources/aws_lb/types'

RSpec.describe "aws_lb resource function" do
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
  let(:subnet_ids) { ["subnet-12345", "subnet-67890"] }
  let(:security_group_ids) { ["sg-abcdef", "sg-12345"] }
  
  describe "LoadBalancerAttributes validation" do
    it "accepts minimal required attributes" do
      attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        subnet_ids: subnet_ids
      })
      
      expect(attrs.load_balancer_type).to eq("application")
      expect(attrs.internal).to eq(false)
      expect(attrs.subnet_ids).to eq(subnet_ids)
      expect(attrs.security_groups).to eq([])
      expect(attrs.enable_deletion_protection).to eq(false)
      expect(attrs.tags).to eq({})
    end
    
    it "accepts application load balancer with security groups" do
      attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        load_balancer_type: "application",
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        internal: false
      })
      
      expect(attrs.load_balancer_type).to eq("application")
      expect(attrs.security_groups).to eq(security_group_ids)
      expect(attrs.internal).to eq(false)
    end
    
    it "accepts network load balancer configuration" do
      attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        load_balancer_type: "network",
        subnet_ids: subnet_ids,
        enable_cross_zone_load_balancing: true,
        internal: true
      })
      
      expect(attrs.load_balancer_type).to eq("network")
      expect(attrs.enable_cross_zone_load_balancing).to eq(true)
      expect(attrs.internal).to eq(true)
    end
    
    it "accepts gateway load balancer configuration" do
      attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        load_balancer_type: "gateway",
        subnet_ids: subnet_ids
      })
      
      expect(attrs.load_balancer_type).to eq("gateway")
    end
    
    it "validates security groups only allowed for ALB" do
      expect {
        Pangea::Resources::AWS::LoadBalancerAttributes.new({
          load_balancer_type: "network",
          subnet_ids: subnet_ids,
          security_groups: security_group_ids
        })
      }.to raise_error(Dry::Struct::Error, /security_groups can only be specified for application load balancers/)
    end
    
    it "validates cross-zone load balancing only for NLB" do
      expect {
        Pangea::Resources::AWS::LoadBalancerAttributes.new({
          load_balancer_type: "application",
          subnet_ids: subnet_ids,
          enable_cross_zone_load_balancing: true
        })
      }.to raise_error(Dry::Struct::Error, /enable_cross_zone_load_balancing can only be specified for network load balancers/)
    end
    
    it "validates minimum subnet requirement" do
      expect {
        Pangea::Resources::AWS::LoadBalancerAttributes.new({
          subnet_ids: ["subnet-12345"]  # Only 1 subnet, need at least 2
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates load balancer type enum" do
      expect {
        Pangea::Resources::AWS::LoadBalancerAttributes.new({
          load_balancer_type: "classic",  # Invalid type
          subnet_ids: subnet_ids
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates IP address type enum" do
      expect {
        Pangea::Resources::AWS::LoadBalancerAttributes.new({
          subnet_ids: subnet_ids,
          ip_address_type: "ipv6"  # Invalid, should be ipv4 or dualstack
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts valid IP address types" do
      ipv4_attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        subnet_ids: subnet_ids,
        ip_address_type: "ipv4"
      })
      
      dualstack_attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        subnet_ids: subnet_ids,
        ip_address_type: "dualstack"
      })
      
      expect(ipv4_attrs.ip_address_type).to eq("ipv4")
      expect(dualstack_attrs.ip_address_type).to eq("dualstack")
    end
    
    it "accepts access logs configuration" do
      attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        subnet_ids: subnet_ids,
        access_logs: {
          enabled: true,
          bucket: "my-access-logs-bucket",
          prefix: "alb-logs"
        }
      })
      
      expect(attrs.access_logs[:enabled]).to eq(true)
      expect(attrs.access_logs[:bucket]).to eq("my-access-logs-bucket")
      expect(attrs.access_logs[:prefix]).to eq("alb-logs")
    end
    
    it "validates access logs requires bucket when enabled" do
      expect {
        Pangea::Resources::AWS::LoadBalancerAttributes.new({
          subnet_ids: subnet_ids,
          access_logs: {
            enabled: true
            # Missing required bucket
          }
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "accepts comprehensive configuration" do
      attrs = Pangea::Resources::AWS::LoadBalancerAttributes.new({
        name: "web-application-lb",
        load_balancer_type: "application",
        internal: false,
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        ip_address_type: "dualstack",
        enable_deletion_protection: true,
        access_logs: {
          enabled: true,
          bucket: "access-logs-bucket",
          prefix: "web-alb"
        },
        tags: {
          Name: "web-alb",
          Environment: "production",
          Application: "web-app"
        }
      })
      
      expect(attrs.name).to eq("web-application-lb")
      expect(attrs.load_balancer_type).to eq("application")
      expect(attrs.internal).to eq(false)
      expect(attrs.subnet_ids).to eq(subnet_ids)
      expect(attrs.security_groups).to eq(security_group_ids)
      expect(attrs.ip_address_type).to eq("dualstack")
      expect(attrs.enable_deletion_protection).to eq(true)
      expect(attrs.access_logs[:enabled]).to eq(true)
      expect(attrs.tags[:Environment]).to eq("production")
    end
  end
  
  describe "aws_lb function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_lb(:test, {
        subnet_ids: subnet_ids
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_lb')
      expect(ref.name).to eq(:test)
    end
    
    it "creates application load balancer with security groups" do
      ref = test_instance.aws_lb(:web_alb, {
        name: "web-application-lb",
        load_balancer_type: "application",
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        internal: false
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("web-application-lb")
      expect(attrs[:load_balancer_type]).to eq("application")
      expect(attrs[:subnet_ids]).to eq(subnet_ids)
      expect(attrs[:security_groups]).to eq(security_group_ids)
      expect(attrs[:internal]).to eq(false)
    end
    
    it "creates network load balancer with cross-zone load balancing" do
      ref = test_instance.aws_lb(:api_nlb, {
        name: "api-network-lb",
        load_balancer_type: "network",
        subnet_ids: subnet_ids,
        enable_cross_zone_load_balancing: true,
        internal: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("api-network-lb")
      expect(attrs[:load_balancer_type]).to eq("network")
      expect(attrs[:enable_cross_zone_load_balancing]).to eq(true)
      expect(attrs[:internal]).to eq(true)
    end
    
    it "creates gateway load balancer" do
      ref = test_instance.aws_lb(:security_gwlb, {
        name: "security-gateway-lb",
        load_balancer_type: "gateway",
        subnet_ids: subnet_ids
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("security-gateway-lb")
      expect(attrs[:load_balancer_type]).to eq("gateway")
    end
    
    it "creates internal load balancer" do
      ref = test_instance.aws_lb(:internal_lb, {
        load_balancer_type: "application",
        internal: true,
        subnet_ids: subnet_ids,
        security_groups: security_group_ids
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:internal]).to eq(true)
      expect(attrs[:load_balancer_type]).to eq("application")
    end
    
    it "creates load balancer with deletion protection" do
      ref = test_instance.aws_lb(:protected_lb, {
        subnet_ids: subnet_ids,
        enable_deletion_protection: true
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:enable_deletion_protection]).to eq(true)
    end
    
    it "creates load balancer with access logs" do
      ref = test_instance.aws_lb(:logged_lb, {
        subnet_ids: subnet_ids,
        access_logs: {
          enabled: true,
          bucket: "access-logs-bucket",
          prefix: "lb-logs"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:access_logs][:enabled]).to eq(true)
      expect(attrs[:access_logs][:bucket]).to eq("access-logs-bucket")
      expect(attrs[:access_logs][:prefix]).to eq("lb-logs")
    end
    
    it "creates load balancer with comprehensive configuration" do
      ref = test_instance.aws_lb(:comprehensive, {
        name: "comprehensive-lb",
        load_balancer_type: "application",
        internal: false,
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        ip_address_type: "dualstack",
        enable_deletion_protection: true,
        access_logs: {
          enabled: true,
          bucket: "comprehensive-logs",
          prefix: "app-lb"
        },
        tags: {
          Name: "comprehensive-lb",
          Environment: "production",
          Application: "web-app",
          ManagedBy: "pangea"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("comprehensive-lb")
      expect(attrs[:load_balancer_type]).to eq("application")
      expect(attrs[:internal]).to eq(false)
      expect(attrs[:subnet_ids]).to eq(subnet_ids)
      expect(attrs[:security_groups]).to eq(security_group_ids)
      expect(attrs[:ip_address_type]).to eq("dualstack")
      expect(attrs[:enable_deletion_protection]).to eq(true)
      expect(attrs[:access_logs][:enabled]).to eq(true)
      expect(attrs[:tags][:Environment]).to eq("production")
    end
    
    it "validates attributes in function call" do
      expect {
        test_instance.aws_lb(:invalid, {
          load_balancer_type: "network",
          subnet_ids: subnet_ids,
          security_groups: security_group_ids  # Invalid for NLB
        })
      }.to raise_error(Dry::Struct::Error, /security_groups can only be specified for application load balancers/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_lb(:test, {
        subnet_ids: subnet_ids
      })
      
      expected_outputs = [
        :id, :arn, :arn_suffix, :dns_name, :zone_id,
        :canonical_hosted_zone_id, :vpc_id
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_lb.test.")
      end
    end
    
    it "provides computed properties via method delegation" do
      alb_ref = test_instance.aws_lb(:alb_test, {
        load_balancer_type: "application",
        subnet_ids: subnet_ids
      })
      
      expect(alb_ref.is_application_load_balancer?).to eq(true)
      expect(alb_ref.is_network_load_balancer?).to eq(false)
      expect(alb_ref.is_gateway_load_balancer?).to eq(false)
      expect(alb_ref.supports_security_groups?).to eq(true)
      expect(alb_ref.supports_cross_zone_load_balancing?).to eq(false)
    end
    
    it "provides computed properties for network load balancer" do
      nlb_ref = test_instance.aws_lb(:nlb_test, {
        load_balancer_type: "network",
        subnet_ids: subnet_ids
      })
      
      expect(nlb_ref.is_application_load_balancer?).to eq(false)
      expect(nlb_ref.is_network_load_balancer?).to eq(true)
      expect(nlb_ref.is_gateway_load_balancer?).to eq(false)
      expect(nlb_ref.supports_security_groups?).to eq(false)
      expect(nlb_ref.supports_cross_zone_load_balancing?).to eq(true)
    end
    
    it "provides computed properties for internal load balancer" do
      internal_ref = test_instance.aws_lb(:internal_test, {
        subnet_ids: subnet_ids,
        internal: true
      })
      
      external_ref = test_instance.aws_lb(:external_test, {
        subnet_ids: subnet_ids,
        internal: false
      })
      
      expect(internal_ref.is_internal?).to eq(true)
      expect(external_ref.is_internal?).to eq(false)
    end
  end
  
  describe "common load balancer patterns" do
    it "creates a public web application load balancer" do
      ref = test_instance.aws_lb(:web, {
        name: "web-application-lb",
        load_balancer_type: "application",
        internal: false,
        subnet_ids: ["subnet-web-a", "subnet-web-b"],
        security_groups: ["sg-web-lb"],
        ip_address_type: "ipv4",
        enable_deletion_protection: true,
        tags: {
          Name: "web-alb",
          Tier: "web",
          Environment: "production"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:load_balancer_type]).to eq("application")
      expect(attrs[:internal]).to eq(false)
      expect(attrs[:security_groups]).to eq(["sg-web-lb"])
      expect(attrs[:enable_deletion_protection]).to eq(true)
      expect(ref.is_application_load_balancer?).to eq(true)
      expect(ref.supports_security_groups?).to eq(true)
    end
    
    it "creates a high-performance network load balancer" do
      ref = test_instance.aws_lb(:api, {
        name: "api-network-lb",
        load_balancer_type: "network",
        internal: false,
        subnet_ids: ["subnet-api-a", "subnet-api-b"],
        enable_cross_zone_load_balancing: true,
        ip_address_type: "ipv4",
        tags: {
          Name: "api-nlb",
          Service: "api",
          Performance: "high"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:load_balancer_type]).to eq("network")
      expect(attrs[:enable_cross_zone_load_balancing]).to eq(true)
      expect(ref.is_network_load_balancer?).to eq(true)
      expect(ref.supports_cross_zone_load_balancing?).to eq(true)
    end
    
    it "creates an internal application load balancer with access logs" do
      ref = test_instance.aws_lb(:internal_services, {
        name: "internal-services-lb",
        load_balancer_type: "application",
        internal: true,
        subnet_ids: ["subnet-private-a", "subnet-private-b"],
        security_groups: ["sg-internal-lb"],
        access_logs: {
          enabled: true,
          bucket: "internal-lb-access-logs",
          prefix: "internal-services"
        },
        tags: {
          Name: "internal-services-alb",
          Tier: "application",
          Visibility: "internal"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:internal]).to eq(true)
      expect(attrs[:access_logs][:enabled]).to eq(true)
      expect(attrs[:access_logs][:bucket]).to eq("internal-lb-access-logs")
      expect(ref.is_internal?).to eq(true)
    end
    
    it "creates a gateway load balancer for security appliances" do
      ref = test_instance.aws_lb(:security_gateway, {
        name: "security-gateway-lb",
        load_balancer_type: "gateway",
        internal: false,
        subnet_ids: ["subnet-security-a", "subnet-security-b"],
        tags: {
          Name: "security-gateway-lb",
          Purpose: "security-inspection",
          Type: "gateway"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:load_balancer_type]).to eq("gateway")
      expect(ref.is_gateway_load_balancer?).to eq(true)
    end
    
    it "creates a dual-stack IPv4/IPv6 load balancer" do
      ref = test_instance.aws_lb(:dualstack, {
        name: "dualstack-lb",
        load_balancer_type: "application",
        subnet_ids: subnet_ids,
        security_groups: security_group_ids,
        ip_address_type: "dualstack",
        tags: {
          Name: "dualstack-lb",
          IpVersion: "dual"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:ip_address_type]).to eq("dualstack")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_lb(:test_lb, {
        subnet_ids: subnet_ids
      })
      
      expect(ref.outputs[:id]).to eq("${aws_lb.test_lb.id}")
      expect(ref.outputs[:arn]).to eq("${aws_lb.test_lb.arn}")
      expect(ref.outputs[:arn_suffix]).to eq("${aws_lb.test_lb.arn_suffix}")
      expect(ref.outputs[:dns_name]).to eq("${aws_lb.test_lb.dns_name}")
      expect(ref.outputs[:zone_id]).to eq("${aws_lb.test_lb.zone_id}")
      expect(ref.outputs[:canonical_hosted_zone_id]).to eq("${aws_lb.test_lb.canonical_hosted_zone_id}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_lb.test_lb.vpc_id}")
    end
    
    it "can be used with load balancer listeners" do
      lb_ref = test_instance.aws_lb(:for_listener, {
        load_balancer_type: "application",
        subnet_ids: subnet_ids,
        security_groups: security_group_ids
      })
      
      # Simulate using load balancer reference in listener
      lb_arn = lb_ref.outputs[:arn]
      
      expect(lb_arn).to eq("${aws_lb.for_listener.arn}")
    end
    
    it "can be used with target groups" do
      lb_ref = test_instance.aws_lb(:for_targets, {
        load_balancer_type: "application",
        subnet_ids: subnet_ids
      })
      
      # Simulate using load balancer reference in target group attachments
      lb_arn = lb_ref.outputs[:arn]
      vpc_id = lb_ref.outputs[:vpc_id]
      
      expect(lb_arn).to eq("${aws_lb.for_targets.arn}")
      expect(vpc_id).to eq("${aws_lb.for_targets.vpc_id}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_lb(:cross_ref, {
        name: "${var.application}-${var.environment}-lb",
        load_balancer_type: "application",
        subnet_ids: ["${data.aws_subnet.public_a.id}", "${data.aws_subnet.public_b.id}"],
        security_groups: ["${aws_security_group.lb.id}"],
        access_logs: {
          enabled: true,
          bucket: "${aws_s3_bucket.access_logs.bucket}",
          prefix: "${var.application}-lb-logs"
        },
        tags: {
          Name: "${var.application}-load-balancer",
          Environment: "${var.environment}",
          ManagedBy: "terraform"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to include("var.application")
      expect(attrs[:subnet_ids]).to all(include("data.aws_subnet"))
      expect(attrs[:security_groups]).to all(include("aws_security_group"))
      expect(attrs[:access_logs][:bucket]).to include("aws_s3_bucket")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles default values correctly" do
      ref = test_instance.aws_lb(:defaults, {
        subnet_ids: subnet_ids
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:load_balancer_type]).to eq("application")
      expect(attrs[:internal]).to eq(false)
      expect(attrs[:security_groups]).to eq([])
      expect(attrs[:enable_deletion_protection]).to eq(false)
      expect(attrs[:tags]).to eq({})
    end
    
    it "handles nil access logs correctly" do
      ref = test_instance.aws_lb(:no_logs, {
        subnet_ids: subnet_ids,
        access_logs: nil
      })
      
      expect(ref.resource_attributes[:access_logs]).to be_nil
    end
    
    it "handles empty security groups correctly" do
      ref = test_instance.aws_lb(:no_sg, {
        subnet_ids: subnet_ids,
        security_groups: []
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:security_groups]).to eq([])
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_lb(:string_keys, {
        "subnet_ids" => subnet_ids,
        "load_balancer_type" => "network",
        "internal" => true
      })
      
      expect(ref.resource_attributes[:subnet_ids]).to eq(subnet_ids)
      expect(ref.resource_attributes[:load_balancer_type]).to eq("network")
      expect(ref.resource_attributes[:internal]).to eq(true)
    end
    
    it "rejects invalid configurations early" do
      # NLB with security groups
      expect {
        test_instance.aws_lb(:invalid_nlb, {
          load_balancer_type: "network",
          subnet_ids: subnet_ids,
          security_groups: ["sg-12345"]
        })
      }.to raise_error(Dry::Struct::Error, /security_groups can only be specified/)
      
      # ALB with cross-zone load balancing
      expect {
        test_instance.aws_lb(:invalid_alb, {
          load_balancer_type: "application",
          subnet_ids: subnet_ids,
          enable_cross_zone_load_balancing: true
        })
      }.to raise_error(Dry::Struct::Error, /enable_cross_zone_load_balancing can only be specified/)
      
      # Insufficient subnets
      expect {
        test_instance.aws_lb(:insufficient_subnets, {
          subnet_ids: ["subnet-1"]  # Need at least 2
        })
      }.to raise_error(Dry::Struct::Error)
    end
  end
end