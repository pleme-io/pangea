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

# Load aws_lb_target_group resource and types for testing
require 'pangea/resources/aws_lb_target_group/resource'
require 'pangea/resources/aws_lb_target_group/types'

RSpec.describe "aws_lb_target_group resource function" do
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
  let(:vpc_id) { "${aws_vpc.main.id}" }
  
  describe "TargetGroupHealthCheck validation" do
    it "accepts default health check configuration" do
      hc = Pangea::Resources::AWS::Types::TargetGroupHealthCheck.new({})
      
      expect(hc.enabled).to eq(true)
      expect(hc.interval).to eq(30)
      expect(hc.path).to eq('/')
      expect(hc.port).to eq('traffic-port')
      expect(hc.protocol).to eq('HTTP')
      expect(hc.timeout).to eq(5)
      expect(hc.healthy_threshold).to eq(5)
      expect(hc.unhealthy_threshold).to eq(2)
      expect(hc.matcher).to eq('200')
    end
    
    it "accepts custom health check configuration" do
      hc = Pangea::Resources::AWS::Types::TargetGroupHealthCheck.new({
        enabled: true,
        interval: 60,
        path: '/api/health',
        port: '8080',
        protocol: 'HTTPS',
        timeout: 30,
        healthy_threshold: 3,
        unhealthy_threshold: 4,
        matcher: '200-299'
      })
      
      expect(hc.interval).to eq(60)
      expect(hc.path).to eq('/api/health')
      expect(hc.port).to eq('8080')
      expect(hc.protocol).to eq('HTTPS')
      expect(hc.timeout).to eq(30)
      expect(hc.healthy_threshold).to eq(3)
      expect(hc.unhealthy_threshold).to eq(4)
      expect(hc.matcher).to eq('200-299')
    end
    
    it "validates timeout is less than interval" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupHealthCheck.new({
          interval: 30,
          timeout: 30
        })
      }.to raise_error(Dry::Struct::Error, /timeout .* must be less than interval/)
    end
    
    it "validates constraints on numeric values" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupHealthCheck.new({
          interval: 400  # Max is 300
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "converts to hash correctly" do
      hc = Pangea::Resources::AWS::Types::TargetGroupHealthCheck.new({
        path: '/health',
        timeout: 10
      })
      
      hash = hc.to_h
      expect(hash).to include(:enabled, :interval, :path, :port, :protocol, :timeout, :healthy_threshold, :unhealthy_threshold, :matcher)
      expect(hash[:path]).to eq('/health')
      expect(hash[:timeout]).to eq(10)
    end
  end
  
  describe "TargetGroupStickiness validation" do
    it "accepts default stickiness configuration" do
      stickiness = Pangea::Resources::AWS::Types::TargetGroupStickiness.new({})
      
      expect(stickiness.enabled).to eq(false)
      expect(stickiness.type).to eq('lb_cookie')
      expect(stickiness.duration).to eq(86400)
      expect(stickiness.cookie_name).to be_nil
    end
    
    it "accepts lb_cookie stickiness" do
      stickiness = Pangea::Resources::AWS::Types::TargetGroupStickiness.new({
        enabled: true,
        type: 'lb_cookie',
        duration: 3600
      })
      
      expect(stickiness.enabled).to eq(true)
      expect(stickiness.type).to eq('lb_cookie')
      expect(stickiness.duration).to eq(3600)
    end
    
    it "accepts app_cookie stickiness with cookie_name" do
      stickiness = Pangea::Resources::AWS::Types::TargetGroupStickiness.new({
        enabled: true,
        type: 'app_cookie',
        cookie_name: 'JSESSIONID'
      })
      
      expect(stickiness.type).to eq('app_cookie')
      expect(stickiness.cookie_name).to eq('JSESSIONID')
    end
    
    it "validates app_cookie requires cookie_name" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupStickiness.new({
          type: 'app_cookie'
        })
      }.to raise_error(Dry::Struct::Error, /cookie_name is required when stickiness type is 'app_cookie'/)
    end
    
    it "validates duration constraints" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupStickiness.new({
          duration: 700000  # Max is 604800
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "converts to hash correctly" do
      stickiness = Pangea::Resources::AWS::Types::TargetGroupStickiness.new({
        enabled: true,
        type: 'lb_cookie',
        duration: 7200
      })
      
      hash = stickiness.to_h
      expect(hash).to include(:enabled, :type, :duration)
      expect(hash[:duration]).to eq(7200)
      expect(hash).not_to have_key(:cookie_name)
    end
    
    it "excludes duration for app_cookie type" do
      stickiness = Pangea::Resources::AWS::Types::TargetGroupStickiness.new({
        enabled: true,
        type: 'app_cookie',
        cookie_name: 'SESSIONID'
      })
      
      hash = stickiness.to_h
      expect(hash).to include(:enabled, :type, :cookie_name)
      expect(hash).not_to have_key(:duration)
    end
  end
  
  describe "TargetGroupAttributes validation" do
    it "validates required attributes" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          protocol: "HTTP",
          vpc_id: vpc_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates name and name_prefix mutual exclusivity" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          name: "web-tg",
          name_prefix: "web-",
          port: 80,
          protocol: "HTTP",
          vpc_id: vpc_id
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both 'name' and 'name_prefix'/)
    end
    
    it "validates GENEVE protocol requires port 6081" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 8080,
          protocol: "GENEVE",
          vpc_id: vpc_id
        })
      }.to raise_error(Dry::Struct::Error, /GENEVE protocol requires port 6081/)
    end
    
    it "validates protocol_version only for HTTP/HTTPS" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 3306,
          protocol: "TCP",
          vpc_id: vpc_id,
          protocol_version: "HTTP1"
        })
      }.to raise_error(Dry::Struct::Error, /protocol_version can only be set for HTTP\/HTTPS protocols/)
    end
    
    it "validates stickiness only for HTTP/HTTPS" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 3306,
          protocol: "TCP",
          vpc_id: vpc_id,
          stickiness: { enabled: true }
        })
      }.to raise_error(Dry::Struct::Error, /Stickiness can only be enabled for HTTP\/HTTPS target groups/)
    end
    
    it "validates health check path only for HTTP/HTTPS" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 3306,
          protocol: "TCP",
          vpc_id: vpc_id,
          health_check: { path: "/health" }
        })
      }.to raise_error(Dry::Struct::Error, /Health check path can only be set for HTTP\/HTTPS target groups/)
    end
    
    it "accepts valid HTTP target group" do
      attrs = Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "instance",
        health_check: {
          path: "/health",
          interval: 30,
          timeout: 5
        },
        stickiness: {
          enabled: true,
          type: "lb_cookie"
        }
      })
      
      expect(attrs.port).to eq(80)
      expect(attrs.protocol).to eq("HTTP")
      expect(attrs.vpc_id).to eq(vpc_id)
      expect(attrs.target_type).to eq("instance")
      expect(attrs.health_check.path).to eq("/health")
      expect(attrs.stickiness.enabled).to eq(true)
    end
    
    it "accepts valid TCP target group" do
      attrs = Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
        port: 3306,
        protocol: "TCP",
        vpc_id: vpc_id,
        target_type: "instance",
        health_check: {
          protocol: "TCP",
          interval: 10,
          timeout: 5
        }
      })
      
      expect(attrs.port).to eq(3306)
      expect(attrs.protocol).to eq("TCP")
      expect(attrs.health_check.protocol).to eq("TCP")
      expect(attrs.stickiness).to be_nil
    end
    
    it "validates port constraints" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 70000,  # Invalid port
          protocol: "HTTP",
          vpc_id: vpc_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates protocol enum" do
      expect {
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 80,
          protocol: "INVALID",
          vpc_id: vpc_id
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    describe "computed properties" do
      let(:http_attrs) do
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 80,
          protocol: "HTTP",
          vpc_id: vpc_id
        })
      end
      
      let(:tcp_attrs) do
        Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
          port: 3306,
          protocol: "TCP",
          vpc_id: vpc_id
        })
      end
      
      it "detects stickiness support" do
        expect(http_attrs.supports_stickiness?).to eq(true)
        expect(tcp_attrs.supports_stickiness?).to eq(false)
      end
      
      it "detects health check path support" do
        expect(http_attrs.supports_health_check_path?).to eq(true)
        expect(tcp_attrs.supports_health_check_path?).to eq(false)
      end
      
      it "detects network load balancer protocols" do
        expect(http_attrs.is_network_load_balancer?).to eq(false)
        expect(tcp_attrs.is_network_load_balancer?).to eq(true)
      end
    end
    
    it "compacts to_h output correctly" do
      attrs = Pangea::Resources::AWS::Types::TargetGroupAttributes.new({
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        name: "web-tg",
        health_check: {
          path: "/health"
        }
      })
      
      hash = attrs.to_h
      expect(hash).to include(:port, :protocol, :vpc_id, :name, :health_check)
      expect(hash).not_to have_key(:name_prefix)
      expect(hash).not_to have_key(:stickiness)
      expect(hash[:health_check]).to be_a(Hash)
    end
  end
  
  describe "aws_lb_target_group function behavior" do
    it "creates a resource reference with minimal attributes" do
      ref = test_instance.aws_lb_target_group(:test, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_lb_target_group')
      expect(ref.name).to eq(:test)
    end
    
    it "creates a resource reference with name" do
      ref = test_instance.aws_lb_target_group(:named_tg, {
        name: "web-target-group",
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      expect(ref.resource_attributes[:name]).to eq("web-target-group")
      expect(ref.resource_attributes[:name_prefix]).to be_nil
    end
    
    it "creates a resource reference with name_prefix" do
      ref = test_instance.aws_lb_target_group(:prefix_tg, {
        name_prefix: "web-",
        port: 443,
        protocol: "HTTPS",
        vpc_id: vpc_id
      })
      
      expect(ref.resource_attributes[:name_prefix]).to eq("web-")
      expect(ref.resource_attributes[:name]).to be_nil
    end
    
    it "creates a resource reference with comprehensive configuration" do
      ref = test_instance.aws_lb_target_group(:comprehensive, {
        name: "comprehensive-tg",
        port: 8080,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "ip",
        deregistration_delay: 60,
        slow_start: 30,
        protocol_version: "HTTP2",
        health_check: {
          enabled: true,
          interval: 15,
          path: "/api/health",
          timeout: 10,
          healthy_threshold: 2,
          unhealthy_threshold: 3,
          matcher: "200,204"
        },
        stickiness: {
          enabled: true,
          type: "lb_cookie",
          duration: 3600
        },
        tags: {
          Name: "comprehensive-tg",
          Environment: "production"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("comprehensive-tg")
      expect(attrs[:port]).to eq(8080)
      expect(attrs[:protocol]).to eq("HTTP")
      expect(attrs[:target_type]).to eq("ip")
      expect(attrs[:deregistration_delay]).to eq(60)
      expect(attrs[:slow_start]).to eq(30)
      expect(attrs[:protocol_version]).to eq("HTTP2")
      expect(attrs[:health_check][:path]).to eq("/api/health")
      expect(attrs[:stickiness][:duration]).to eq(3600)
      expect(attrs[:tags][:Environment]).to eq("production")
    end
    
    it "validates attributes in function call" do
      expect {
        test_instance.aws_lb_target_group(:invalid, {
          port: 3306,
          protocol: "TCP",
          vpc_id: vpc_id,
          stickiness: { enabled: true }
        })
      }.to raise_error(Dry::Struct::Error, /Stickiness can only be enabled for HTTP\/HTTPS target groups/)
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_lb_target_group(:test, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      expected_outputs = [
        :id, :arn, :arn_suffix, :name, :port, :protocol, :vpc_id,
        :target_type, :health_check, :stickiness
      ]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_lb_target_group.test.")
      end
    end
    
    it "provides computed properties via method delegation" do
      ref = test_instance.aws_lb_target_group(:test, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      expect(ref.supports_stickiness?).to eq(true)
      expect(ref.supports_health_check_path?).to eq(true)
      expect(ref.is_network_load_balancer?).to eq(false)
    end
    
    it "provides computed properties for TCP target group" do
      ref = test_instance.aws_lb_target_group(:tcp_test, {
        port: 3306,
        protocol: "TCP",
        vpc_id: vpc_id
      })
      
      expect(ref.supports_stickiness?).to eq(false)
      expect(ref.supports_health_check_path?).to eq(false)
      expect(ref.is_network_load_balancer?).to eq(true)
    end
  end
  
  describe "common target group patterns" do
    it "creates an HTTP target group for ALB" do
      ref = test_instance.aws_lb_target_group(:web, {
        name: "web-target-group",
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "instance",
        health_check: {
          enabled: true,
          path: "/health",
          interval: 30,
          timeout: 5,
          healthy_threshold: 2,
          unhealthy_threshold: 3,
          matcher: "200"
        },
        stickiness: {
          enabled: true,
          type: "lb_cookie",
          duration: 86400
        },
        tags: {
          Name: "web-target-group",
          Type: "web"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:protocol]).to eq("HTTP")
      expect(attrs[:health_check][:path]).to eq("/health")
      expect(attrs[:stickiness][:enabled]).to eq(true)
      expect(ref.supports_stickiness?).to eq(true)
    end
    
    it "creates a TCP target group for NLB" do
      ref = test_instance.aws_lb_target_group(:tcp_app, {
        name: "tcp-app-target-group",
        port: 3306,
        protocol: "TCP",
        vpc_id: vpc_id,
        target_type: "instance",
        deregistration_delay: 60,
        health_check: {
          enabled: true,
          protocol: "TCP",
          interval: 10,
          timeout: 5,
          healthy_threshold: 2,
          unhealthy_threshold: 2
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:protocol]).to eq("TCP")
      expect(attrs[:deregistration_delay]).to eq(60)
      expect(attrs[:health_check][:protocol]).to eq("TCP")
      expect(ref.is_network_load_balancer?).to eq(true)
      expect(ref.supports_stickiness?).to eq(false)
    end
    
    it "creates a Lambda target group" do
      ref = test_instance.aws_lb_target_group(:lambda, {
        name: "lambda-target-group",
        port: 443,
        protocol: "HTTPS",
        vpc_id: vpc_id,
        target_type: "lambda",
        health_check: {
          enabled: false
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:target_type]).to eq("lambda")
      expect(attrs[:health_check][:enabled]).to eq(false)
    end
    
    it "creates an IP-based target group for containers" do
      ref = test_instance.aws_lb_target_group(:container, {
        name_prefix: "container-",
        port: 8080,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "ip",
        slow_start: 30,
        deregistration_delay: 30,
        health_check: {
          path: "/api/health",
          interval: 15,
          timeout: 10,
          healthy_threshold: 2,
          unhealthy_threshold: 3
        },
        tags: {
          Name: "container-target-group",
          Type: "container"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:target_type]).to eq("ip")
      expect(attrs[:slow_start]).to eq(30)
      expect(attrs[:deregistration_delay]).to eq(30)
      expect(attrs[:health_check][:path]).to eq("/api/health")
    end
    
    it "creates an HTTPS target group with app cookie stickiness" do
      ref = test_instance.aws_lb_target_group(:app_cookie, {
        name: "app-cookie-tg",
        port: 443,
        protocol: "HTTPS",
        vpc_id: vpc_id,
        protocol_version: "HTTP2",
        stickiness: {
          enabled: true,
          type: "app_cookie",
          cookie_name: "JSESSIONID"
        },
        health_check: {
          protocol: "HTTPS",
          path: "/api/status",
          matcher: "200-299"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:protocol]).to eq("HTTPS")
      expect(attrs[:protocol_version]).to eq("HTTP2")
      expect(attrs[:stickiness][:type]).to eq("app_cookie")
      expect(attrs[:stickiness][:cookie_name]).to eq("JSESSIONID")
      expect(attrs[:health_check][:protocol]).to eq("HTTPS")
    end
    
    it "creates a UDP target group for NLB" do
      ref = test_instance.aws_lb_target_group(:udp, {
        name: "udp-target-group",
        port: 53,
        protocol: "UDP",
        vpc_id: vpc_id,
        target_type: "instance",
        health_check: {
          enabled: true,
          protocol: "TCP",  # UDP health checks use TCP
          port: "8080",
          interval: 10
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:protocol]).to eq("UDP")
      expect(attrs[:health_check][:protocol]).to eq("TCP")
      expect(ref.is_network_load_balancer?).to eq(true)
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_lb_target_group(:test_tg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      expect(ref.outputs[:id]).to eq("${aws_lb_target_group.test_tg.id}")
      expect(ref.outputs[:arn]).to eq("${aws_lb_target_group.test_tg.arn}")
      expect(ref.outputs[:arn_suffix]).to eq("${aws_lb_target_group.test_tg.arn_suffix}")
      expect(ref.outputs[:name]).to eq("${aws_lb_target_group.test_tg.name}")
      expect(ref.outputs[:port]).to eq("${aws_lb_target_group.test_tg.port}")
      expect(ref.outputs[:protocol]).to eq("${aws_lb_target_group.test_tg.protocol}")
    end
    
    it "can be used with Auto Scaling Group" do
      tg_ref = test_instance.aws_lb_target_group(:for_asg, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id
      })
      
      # Simulate using target group reference in ASG
      tg_arn = tg_ref.outputs[:arn]
      
      expect(tg_arn).to eq("${aws_lb_target_group.for_asg.arn}")
    end
    
    it "supports complex cross-resource references" do
      ref = test_instance.aws_lb_target_group(:cross_ref, {
        name: "${var.application}-${var.environment}-tg",
        port: 80,
        protocol: "HTTP",
        vpc_id: "${data.aws_vpc.main.id}",
        health_check: {
          path: "${var.health_check_path}",
          matcher: "${var.success_codes}"
        },
        tags: {
          Name: "${var.application}-target-group",
          Environment: "${var.environment}",
          Application: "${var.application}"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to include("var.application")
      expect(attrs[:vpc_id]).to include("data.aws_vpc.main.id")
      expect(attrs[:health_check][:path]).to include("var.health_check_path")
      expect(attrs[:tags][:Environment]).to include("var.environment")
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles empty health check correctly" do
      ref = test_instance.aws_lb_target_group(:no_hc, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        health_check: nil
      })
      
      expect(ref.resource_attributes[:health_check]).to be_nil
    end
    
    it "handles empty stickiness correctly" do
      ref = test_instance.aws_lb_target_group(:no_sticky, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        stickiness: nil
      })
      
      expect(ref.resource_attributes[:stickiness]).to be_nil
    end
    
    it "handles default values correctly" do
      ref = test_instance.aws_lb_target_group(:defaults, {
        port: 80,
        protocol: "HTTP",
        vpc_id: vpc_id,
        target_type: "instance",  # Default value
        deregistration_delay: 300, # Default value
        slow_start: 0, # Default value
        ip_address_type: "ipv4" # Default value
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:target_type]).to eq("instance")
      expect(attrs[:deregistration_delay]).to eq(300)
      expect(attrs[:ip_address_type]).to eq("ipv4")
      # slow_start should not be present since it's 0 (default)
      expect(attrs).not_to have_key(:slow_start)
    end
    
    it "handles string keys in attributes" do
      ref = test_instance.aws_lb_target_group(:string_keys, {
        "port" => 80,
        "protocol" => "HTTP",
        "vpc_id" => vpc_id,
        "target_type" => "ip"
      })
      
      expect(ref.resource_attributes[:port]).to eq(80)
      expect(ref.resource_attributes[:protocol]).to eq("HTTP")
      expect(ref.resource_attributes[:target_type]).to eq("ip")
    end
  end
end