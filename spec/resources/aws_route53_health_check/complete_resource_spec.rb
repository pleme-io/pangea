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

# Load aws_route53_health_check resource and types for testing
require 'pangea/resources/aws_route53_health_check/resource'
require 'pangea/resources/aws_route53_health_check/types'

RSpec.describe "aws_route53_health_check resource function" do
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
  
  describe "Route53HealthCheckAttributes validation" do
    it "accepts HTTP health check configuration" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        port: 80,
        resource_path: "/health",
        failure_threshold: 3,
        request_interval: 30,
        tags: {
          Name: "example-http-check"
        }
      })
      
      expect(health_check.type).to eq("HTTP")
      expect(health_check.fqdn).to eq("example.com")
      expect(health_check.port).to eq(80)
      expect(health_check.resource_path).to eq("/health")
    end
    
    it "accepts HTTPS health check with string matching" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTPS_STR_MATCH",
        fqdn: "api.example.com",
        port: 443,
        resource_path: "/status",
        search_string: "OK",
        enable_sni: true,
        failure_threshold: 2,
        request_interval: 10
      })
      
      expect(health_check.type).to eq("HTTPS_STR_MATCH")
      expect(health_check.search_string).to eq("OK")
      expect(health_check.enable_sni).to eq(true)
      expect(health_check.supports_string_matching?).to eq(true)
      expect(health_check.supports_ssl?).to eq(true)
    end
    
    it "validates HTTP/HTTPS requires either FQDN or IP" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "HTTP",
          port: 80,
          resource_path: "/health"
        })
      }.to raise_error(Dry::Struct::Error, /HTTP\/HTTPS health checks require either fqdn or ip_address/)
    end
    
    it "validates cannot have both FQDN and IP" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "HTTP",
          fqdn: "example.com",
          ip_address: "192.0.2.1",
          port: 80
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both fqdn and ip_address/)
    end
    
    it "validates string match types require search string" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "HTTP_STR_MATCH",
          fqdn: "example.com"
        })
      }.to raise_error(Dry::Struct::Error, /HTTP_STR_MATCH requires search_string parameter/)
    end
    
    it "accepts TCP health check configuration" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "TCP",
        ip_address: "192.0.2.1",
        port: 5432,
        failure_threshold: 3,
        request_interval: 30
      })
      
      expect(health_check.type).to eq("TCP")
      expect(health_check.ip_address).to eq("192.0.2.1")
      expect(health_check.port).to eq(5432)
      expect(health_check.is_endpoint_health_check?).to eq(true)
    end
    
    it "validates TCP requires port" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "TCP",
          fqdn: "db.example.com"
        })
      }.to raise_error(Dry::Struct::Error, /TCP health checks require port parameter/)
    end
    
    it "validates TCP cannot have resource_path or search_string" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "TCP",
          fqdn: "db.example.com",
          port: 5432,
          resource_path: "/health"
        })
      }.to raise_error(Dry::Struct::Error, /TCP health checks cannot have resource_path or search_string/)
    end
    
    it "accepts CALCULATED health check configuration" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "CALCULATED",
        child_health_checks: ["health-check-id-1", "health-check-id-2", "health-check-id-3"],
        child_health_threshold: 2,
        failure_threshold: 1,
        request_interval: 30
      })
      
      expect(health_check.type).to eq("CALCULATED")
      expect(health_check.child_health_checks).to have(3).items
      expect(health_check.child_health_threshold).to eq(2)
      expect(health_check.is_calculated_health_check?).to eq(true)
    end
    
    it "validates CALCULATED requires child health checks" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "CALCULATED",
          child_health_checks: [],
          child_health_threshold: 1
        })
      }.to raise_error(Dry::Struct::Error, /CALCULATED health checks require child_health_checks/)
    end
    
    it "validates CALCULATED requires child threshold" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "CALCULATED",
          child_health_checks: ["health-check-id-1"]
        })
      }.to raise_error(Dry::Struct::Error, /CALCULATED health checks require child_health_threshold/)
    end
    
    it "validates CALCULATED cannot have endpoint parameters" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "CALCULATED",
          child_health_checks: ["health-check-id-1"],
          child_health_threshold: 1,
          fqdn: "example.com"
        })
      }.to raise_error(Dry::Struct::Error, /CALCULATED health checks cannot have endpoint parameters/)
    end
    
    it "accepts CLOUDWATCH_METRIC health check configuration" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "CLOUDWATCH_METRIC",
        cloudwatch_alarm_name: "high-cpu-alarm",
        cloudwatch_alarm_region: "us-east-1",
        insufficient_data_health_status: "Unhealthy",
        failure_threshold: 1,
        request_interval: 30
      })
      
      expect(health_check.type).to eq("CLOUDWATCH_METRIC")
      expect(health_check.cloudwatch_alarm_name).to eq("high-cpu-alarm")
      expect(health_check.cloudwatch_alarm_region).to eq("us-east-1")
      expect(health_check.is_cloudwatch_health_check?).to eq(true)
    end
    
    it "validates CLOUDWATCH_METRIC requires alarm details" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "CLOUDWATCH_METRIC"
        })
      }.to raise_error(Dry::Struct::Error, /CLOUDWATCH_METRIC requires cloudwatch_alarm_region and cloudwatch_alarm_name/)
    end
    
    it "validates IP address format" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "HTTP",
          ip_address: "invalid.ip.address",
          port: 80
        })
      }.to raise_error(Dry::Struct::Error, /Invalid IP address format/)
    end
    
    it "validates FQDN format" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "HTTP",
          fqdn: "-invalid-.domain.com",
          port: 80
        })
      }.to raise_error(Dry::Struct::Error, /Invalid FQDN format/)
    end
    
    it "sets default ports for HTTP/HTTPS" do
      http_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com"
      })
      expect(http_check.port).to eq(80)
      
      https_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTPS",
        fqdn: "example.com"
      })
      expect(https_check.port).to eq(443)
    end
    
    it "normalizes resource path" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        resource_path: "health"
      })
      expect(health_check.resource_path).to eq("/health")
    end
    
    it "accepts latency measurement" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        measure_latency: true
      })
      expect(health_check.measure_latency).to eq(true)
    end
    
    it "accepts inverted health check" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        invert_healthcheck: true
      })
      expect(health_check.invert_healthcheck).to eq(true)
    end
    
    it "accepts disabled health check" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        disabled: true
      })
      expect(health_check.disabled).to eq(true)
    end
    
    it "accepts regions for health checking" do
      health_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        regions: ["us-east-1", "us-west-2", "eu-west-1"]
      })
      expect(health_check.regions).to have(3).items
    end
    
    it "validates AWS regions" do
      expect {
        Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
          type: "HTTP",
          fqdn: "example.com",
          regions: ["invalid-region"]
        })
      }.to raise_error(Dry::Struct::Error, /Invalid AWS region/)
    end
    
    it "calculates estimated monthly cost" do
      basic_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com"
      })
      expect(basic_check.estimated_monthly_cost).to eq("$0.5/month")
      
      latency_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        measure_latency: true
      })
      expect(latency_check.estimated_monthly_cost).to eq("$1.5/month")
      
      fast_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        request_interval: 10
      })
      expect(fast_check.estimated_monthly_cost).to eq("$2.5/month")
    end
    
    it "provides configuration warnings" do
      # Disabled health check warning
      disabled_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        disabled: true
      })
      expect(disabled_check.validate_configuration).to include("Health check is disabled and will not perform checks")
      
      # Fast interval with low threshold warning
      fast_check = Pangea::Resources::AWS::Types::Route53HealthCheckAttributes.new({
        type: "HTTP",
        fqdn: "example.com",
        request_interval: 10,
        failure_threshold: 1
      })
      expect(fast_check.validate_configuration).to include("Fast interval (10s) with low failure threshold may cause false positives")
    end
  end
  
  describe "aws_route53_health_check function" do
    it "creates basic HTTP health check" do
      result = test_instance.aws_route53_health_check(:http_check, {
        type: "HTTP",
        fqdn: "example.com",
        port: 80,
        resource_path: "/health",
        failure_threshold: 3,
        request_interval: 30,
        tags: {
          Name: "example-http-check",
          Environment: "production"
        }
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_route53_health_check')
      expect(result.name).to eq(:http_check)
      expect(result.id).to eq("${aws_route53_health_check.http_check.id}")
    end
    
    it "creates HTTPS health check with string matching" do
      result = test_instance.aws_route53_health_check(:https_string_match, {
        type: "HTTPS_STR_MATCH",
        fqdn: "api.example.com",
        port: 443,
        resource_path: "/status",
        search_string: "OK",
        enable_sni: true,
        measure_latency: true,
        failure_threshold: 2,
        request_interval: 10
      })
      
      expect(result.resource_attributes[:type]).to eq("HTTPS_STR_MATCH")
      expect(result.resource_attributes[:search_string]).to eq("OK")
      expect(result.supports_string_matching?).to eq(true)
      expect(result.supports_ssl?).to eq(true)
    end
    
    it "creates TCP health check" do
      result = test_instance.aws_route53_health_check(:tcp_check, {
        type: "TCP",
        ip_address: "192.0.2.1",
        port: 5432,
        failure_threshold: 3,
        request_interval: 30
      })
      
      expect(result.resource_attributes[:type]).to eq("TCP")
      expect(result.resource_attributes[:ip_address]).to eq("192.0.2.1")
      expect(result.resource_attributes[:port]).to eq(5432)
      expect(result.is_endpoint_health_check?).to eq(true)
    end
    
    it "creates CALCULATED health check" do
      result = test_instance.aws_route53_health_check(:calculated_check, {
        type: "CALCULATED",
        child_health_checks: ["hc-1234", "hc-5678", "hc-9012"],
        child_health_threshold: 2,
        failure_threshold: 1,
        reference_name: "Multi-region health check"
      })
      
      expect(result.resource_attributes[:type]).to eq("CALCULATED")
      expect(result.resource_attributes[:child_health_checks]).to have(3).items
      expect(result.is_calculated_health_check?).to eq(true)
    end
    
    it "creates CloudWatch metric health check" do
      result = test_instance.aws_route53_health_check(:cloudwatch_check, {
        type: "CLOUDWATCH_METRIC",
        cloudwatch_alarm_name: "high-cpu-usage",
        cloudwatch_alarm_region: "us-east-1",
        insufficient_data_health_status: "Unhealthy",
        failure_threshold: 1
      })
      
      expect(result.resource_attributes[:type]).to eq("CLOUDWATCH_METRIC")
      expect(result.resource_attributes[:cloudwatch_alarm_name]).to eq("high-cpu-usage")
      expect(result.is_cloudwatch_health_check?).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_route53_health_check(:test, {
        type: "HTTP",
        fqdn: "example.com",
        port: 80,
        resource_path: "/health"
      })
      
      expect(result.id).to eq("${aws_route53_health_check.test.id}")
      expect(result.arn).to eq("${aws_route53_health_check.test.arn}")
      expect(result.reference_name).to eq("${aws_route53_health_check.test.reference_name}")
      expect(result.type).to eq("${aws_route53_health_check.test.type}")
      expect(result.fqdn).to eq("${aws_route53_health_check.test.fqdn}")
      expect(result.port).to eq("${aws_route53_health_check.test.port}")
      expect(result.failure_threshold).to eq("${aws_route53_health_check.test.failure_threshold}")
      expect(result.request_interval).to eq("${aws_route53_health_check.test.request_interval}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_route53_health_check(:computed_test, {
        type: "HTTPS_STR_MATCH",
        fqdn: "api.example.com",
        port: 443,
        resource_path: "/status",
        search_string: "OK",
        enable_sni: true,
        measure_latency: true,
        request_interval: 10
      })
      
      expect(result.is_endpoint_health_check?).to eq(true)
      expect(result.is_calculated_health_check?).to eq(false)
      expect(result.is_cloudwatch_health_check?).to eq(false)
      expect(result.supports_string_matching?).to eq(true)
      expect(result.supports_ssl?).to eq(true)
      expect(result.endpoint_identifier).to eq("api.example.com")
      expect(result.default_port_for_type).to eq(443)
      expect(result.estimated_monthly_cost).to eq("$3.5/month")
    end
  end
  
  describe "Route53HealthCheckConfigs module" do
    it "creates HTTP check configuration" do
      config = Pangea::Resources::AWS::Types::Route53HealthCheckConfigs.http_check("example.com", 
        path: "/health",
        search_string: "OK"
      )
      
      expect(config[:type]).to eq("HTTP_STR_MATCH")
      expect(config[:fqdn]).to eq("example.com")
      expect(config[:resource_path]).to eq("/health")
      expect(config[:search_string]).to eq("OK")
    end
    
    it "creates HTTPS check configuration" do
      config = Pangea::Resources::AWS::Types::Route53HealthCheckConfigs.https_check("secure.example.com",
        port: 8443,
        path: "/status"
      )
      
      expect(config[:type]).to eq("HTTPS")
      expect(config[:port]).to eq(8443)
      expect(config[:enable_sni]).to eq(true)
    end
    
    it "creates TCP check configuration" do
      config = Pangea::Resources::AWS::Types::Route53HealthCheckConfigs.tcp_check("db.example.com", 5432)
      
      expect(config[:type]).to eq("TCP")
      expect(config[:fqdn]).to eq("db.example.com")
      expect(config[:port]).to eq(5432)
    end
    
    it "creates load balancer check configuration" do
      config = Pangea::Resources::AWS::Types::Route53HealthCheckConfigs.load_balancer_check("alb-123456.us-east-1.elb.amazonaws.com",
        path: "/health",
        search_string: "healthy"
      )
      
      expect(config[:type]).to eq("HTTPS_STR_MATCH")
      expect(config[:port]).to eq(443)
      expect(config[:search_string]).to eq("healthy")
      expect(config[:enable_sni]).to eq(true)
    end
    
    it "creates calculated check configuration" do
      config = Pangea::Resources::AWS::Types::Route53HealthCheckConfigs.calculated_check(
        ["hc-1234", "hc-5678", "hc-9012"],
        min_healthy: 2
      )
      
      expect(config[:type]).to eq("CALCULATED")
      expect(config[:child_health_checks]).to have(3).items
      expect(config[:child_health_threshold]).to eq(2)
    end
    
    it "creates CloudWatch check configuration" do
      config = Pangea::Resources::AWS::Types::Route53HealthCheckConfigs.cloudwatch_check(
        "high-cpu-alarm",
        "us-east-1",
        insufficient_data_status: "Unhealthy"
      )
      
      expect(config[:type]).to eq("CLOUDWATCH_METRIC")
      expect(config[:cloudwatch_alarm_name]).to eq("high-cpu-alarm")
      expect(config[:insufficient_data_health_status]).to eq("Unhealthy")
    end
  end
  
  describe "health check patterns" do
    it "creates multi-region failover health check" do
      result = test_instance.aws_route53_health_check(:multi_region, {
        type: "HTTPS_STR_MATCH",
        fqdn: "api.example.com",
        port: 443,
        resource_path: "/health",
        search_string: "OK",
        enable_sni: true,
        failure_threshold: 2,
        request_interval: 30,
        regions: ["us-east-1", "us-west-2", "eu-west-1"],
        tags: {
          Name: "multi-region-health-check",
          Pattern: "failover"
        }
      })
      
      expect(result.resource_attributes[:regions]).to have(3).items
      expect(result.supports_ssl?).to eq(true)
    end
    
    it "creates database health monitoring" do
      result = test_instance.aws_route53_health_check(:database_health, {
        type: "TCP",
        fqdn: "db.internal.example.com",
        port: 5432,
        failure_threshold: 3,
        request_interval: 30,
        tags: {
          Name: "database-health",
          Service: "postgresql"
        }
      })
      
      expect(result.resource_attributes[:type]).to eq("TCP")
      expect(result.is_endpoint_health_check?).to eq(true)
    end
    
    it "creates hierarchical health check" do
      # Create individual checks first
      api_check = test_instance.aws_route53_health_check(:api_health, {
        type: "HTTPS_STR_MATCH",
        fqdn: "api.example.com",
        search_string: "OK"
      })
      
      db_check = test_instance.aws_route53_health_check(:db_health, {
        type: "TCP",
        fqdn: "db.example.com",
        port: 5432
      })
      
      cache_check = test_instance.aws_route53_health_check(:cache_health, {
        type: "TCP",
        fqdn: "cache.example.com",
        port: 6379
      })
      
      # Create calculated health check
      result = test_instance.aws_route53_health_check(:system_health, {
        type: "CALCULATED",
        child_health_checks: [api_check.id, db_check.id, cache_check.id],
        child_health_threshold: 2,
        reference_name: "System Health - 2 of 3 components must be healthy",
        tags: {
          Name: "system-health",
          Pattern: "hierarchical"
        }
      })
      
      expect(result.is_calculated_health_check?).to eq(true)
      expect(result.resource_attributes[:child_health_checks]).to have(3).items
    end
  end
end