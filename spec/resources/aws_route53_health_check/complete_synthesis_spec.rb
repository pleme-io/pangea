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

# Require the AWS Route53 Health Check module
require 'pangea/resources/aws_route53_health_check/resource'
require 'pangea/resources/aws_route53_health_check/types'

RSpec.describe "aws_route53_health_check synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Extend the synthesizer with our AWS module for resource access
  before do
    synthesizer.extend(Pangea::Resources::AWS)
  end

  describe "basic health check synthesis" do
    it "synthesizes minimal HTTP health check" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:http_basic, {
          type: "HTTP",
          fqdn: "example.com",
          port: 80,
          resource_path: "/health",
          failure_threshold: 3,
          request_interval: 30,
          tags: {
            Name: "basic-http-check"
          }
        })
        
        synthesis
      end
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route53_health_check")
      expect(result["resource"]["aws_route53_health_check"]).to have_key("http_basic")
      
      health_check = result["resource"]["aws_route53_health_check"]["http_basic"]
      expect(health_check["type"]).to eq("HTTP")
      expect(health_check["fqdn"]).to eq("example.com")
      expect(health_check["port"]).to eq(80)
      expect(health_check["resource_path"]).to eq("/health")
      expect(health_check["failure_threshold"]).to eq(3)
      expect(health_check["request_interval"]).to eq(30)
      expect(health_check["tags"]["Name"]).to eq("basic-http-check")
    end
    
    it "synthesizes HTTPS health check with string matching" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:https_string_match, {
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
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["https_string_match"]
      
      expect(health_check["type"]).to eq("HTTPS_STR_MATCH")
      expect(health_check["fqdn"]).to eq("api.example.com")
      expect(health_check["port"]).to eq(443)
      expect(health_check["resource_path"]).to eq("/status")
      expect(health_check["search_string"]).to eq("OK")
      expect(health_check["enable_sni"]).to eq(true)
      expect(health_check["measure_latency"]).to eq(true)
      expect(health_check["request_interval"]).to eq(10)
    end
  end
  
  describe "TCP health check synthesis" do
    it "synthesizes TCP port monitoring" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:tcp_check, {
          type: "TCP",
          ip_address: "192.0.2.1",
          port: 5432,
          failure_threshold: 3,
          request_interval: 30,
          tags: {
            Name: "database-tcp-check",
            Service: "postgresql"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["tcp_check"]
      
      expect(health_check["type"]).to eq("TCP")
      expect(health_check["ip_address"]).to eq("192.0.2.1")
      expect(health_check["port"]).to eq(5432)
      expect(health_check["fqdn"]).to be_nil
      expect(health_check["resource_path"]).to be_nil
      expect(health_check["search_string"]).to be_nil
    end
    
    it "synthesizes TCP with FQDN instead of IP" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:tcp_fqdn, {
          type: "TCP",
          fqdn: "db.example.com",
          port: 3306,
          failure_threshold: 2,
          request_interval: 30,
          measure_latency: true
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["tcp_fqdn"]
      
      expect(health_check["type"]).to eq("TCP")
      expect(health_check["fqdn"]).to eq("db.example.com")
      expect(health_check["port"]).to eq(3306)
      expect(health_check["measure_latency"]).to eq(true)
      expect(health_check["ip_address"]).to be_nil
    end
  end
  
  describe "calculated health check synthesis" do
    it "synthesizes calculated health check with child checks" do
      result = synthesizer.instance_eval do
        # Create child health checks first
        api_check = aws_route53_health_check(:api_health, {
          type: "HTTPS_STR_MATCH",
          fqdn: "api.example.com",
          port: 443,
          resource_path: "/health",
          search_string: "OK"
        })
        
        db_check = aws_route53_health_check(:db_health, {
          type: "TCP",
          fqdn: "db.example.com",
          port: 5432
        })
        
        cache_check = aws_route53_health_check(:cache_health, {
          type: "TCP",
          fqdn: "cache.example.com",
          port: 6379
        })
        
        # Create calculated health check
        aws_route53_health_check(:system_health, {
          type: "CALCULATED",
          child_health_checks: ["hc-api-1234", "hc-db-5678", "hc-cache-9012"],
          child_health_threshold: 2,
          failure_threshold: 1,
          reference_name: "System Health - 2 of 3 components",
          tags: {
            Name: "system-health-check",
            Type: "calculated"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["system_health"]
      
      expect(health_check["type"]).to eq("CALCULATED")
      expect(health_check["child_health_checks"]).to eq(["hc-api-1234", "hc-db-5678", "hc-cache-9012"])
      expect(health_check["child_health_threshold"]).to eq(2)
      expect(health_check["failure_threshold"]).to eq(1)
      expect(health_check["reference_name"]).to eq("System Health - 2 of 3 components")
      
      # Calculated checks should not have endpoint parameters
      expect(health_check["fqdn"]).to be_nil
      expect(health_check["ip_address"]).to be_nil
      expect(health_check["port"]).to be_nil
    end
  end
  
  describe "CloudWatch metric health check synthesis" do
    it "synthesizes CloudWatch alarm-based health check" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:cloudwatch_alarm, {
          type: "CLOUDWATCH_METRIC",
          cloudwatch_alarm_name: "high-cpu-usage",
          cloudwatch_alarm_region: "us-east-1",
          insufficient_data_health_status: "Unhealthy",
          failure_threshold: 1,
          request_interval: 30,
          tags: {
            Name: "cloudwatch-based-health",
            AlarmType: "cpu"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["cloudwatch_alarm"]
      
      expect(health_check["type"]).to eq("CLOUDWATCH_METRIC")
      expect(health_check["cloudwatch_alarm_name"]).to eq("high-cpu-usage")
      expect(health_check["cloudwatch_alarm_region"]).to eq("us-east-1")
      expect(health_check["insufficient_data_health_status"]).to eq("Unhealthy")
      expect(health_check["failure_threshold"]).to eq(1)
      
      # CloudWatch checks should not have endpoint parameters
      expect(health_check["fqdn"]).to be_nil
      expect(health_check["port"]).to be_nil
    end
  end
  
  describe "advanced features synthesis" do
    it "synthesizes health check with latency measurement" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:latency_check, {
          type: "HTTPS",
          fqdn: "app.example.com",
          port: 443,
          resource_path: "/api/health",
          measure_latency: true,
          failure_threshold: 3,
          request_interval: 30
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["latency_check"]
      expect(health_check["measure_latency"]).to eq(true)
    end
    
    it "synthesizes inverted health check" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:inverted_check, {
          type: "HTTP",
          fqdn: "maintenance.example.com",
          port: 80,
          resource_path: "/maintenance",
          invert_healthcheck: true,
          failure_threshold: 1,
          request_interval: 30,
          tags: {
            Name: "maintenance-check",
            Purpose: "inverted"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["inverted_check"]
      expect(health_check["invert_healthcheck"]).to eq(true)
    end
    
    it "synthesizes disabled health check" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:disabled_check, {
          type: "HTTP",
          fqdn: "example.com",
          port: 80,
          disabled: true,
          failure_threshold: 3,
          request_interval: 30
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["disabled_check"]
      expect(health_check["disabled"]).to eq(true)
    end
    
    it "synthesizes health check with specific regions" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:regional_check, {
          type: "HTTPS",
          fqdn: "global.example.com",
          port: 443,
          resource_path: "/health",
          regions: ["us-east-1", "us-west-2", "eu-west-1"],
          failure_threshold: 3,
          request_interval: 30
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["regional_check"]
      expect(health_check["regions"]).to eq(["us-east-1", "us-west-2", "eu-west-1"])
    end
  end
  
  describe "real-world patterns synthesis" do
    it "synthesizes load balancer health check" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:alb_health, {
          type: "HTTPS_STR_MATCH",
          fqdn: "alb-123456.us-east-1.elb.amazonaws.com",
          port: 443,
          resource_path: "/health",
          search_string: "healthy",
          enable_sni: true,
          failure_threshold: 3,
          request_interval: 30,
          tags: {
            Name: "alb-health-check",
            LoadBalancer: "production"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["alb_health"]
      
      expect(health_check["type"]).to eq("HTTPS_STR_MATCH")
      expect(health_check["fqdn"]).to include("elb.amazonaws.com")
      expect(health_check["search_string"]).to eq("healthy")
      expect(health_check["enable_sni"]).to eq(true)
    end
    
    it "synthesizes multi-region failover health check" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:failover_primary, {
          type: "HTTPS_STR_MATCH",
          fqdn: "app-primary.example.com",
          port: 443,
          resource_path: "/health",
          search_string: "OK",
          enable_sni: true,
          measure_latency: false,
          failure_threshold: 2,
          request_interval: 30,
          reference_name: "Primary Region Health Check",
          tags: {
            Name: "primary-health",
            Region: "us-east-1",
            FailoverRole: "PRIMARY"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["failover_primary"]
      
      expect(health_check["reference_name"]).to eq("Primary Region Health Check")
      expect(health_check["tags"]["FailoverRole"]).to eq("PRIMARY")
    end
    
    it "synthesizes API endpoint monitoring" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:api_monitoring, {
          type: "HTTPS_STR_MATCH",
          fqdn: "api.example.com",
          port: 443,
          resource_path: "/v2/health",
          search_string: "{\"status\":\"ok\"}",
          enable_sni: true,
          measure_latency: true,
          failure_threshold: 3,
          request_interval: 10,
          tags: {
            Name: "api-endpoint-health",
            API: "v2",
            ExpectedResponse: "json"
          }
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["api_monitoring"]
      
      expect(health_check["search_string"]).to eq("{\"status\":\"ok\"}")
      expect(health_check["request_interval"]).to eq(10)
      expect(health_check["measure_latency"]).to eq(true)
    end
    
    it "synthesizes database cluster monitoring" do
      result = synthesizer.instance_eval do
        # Master database
        master_check = aws_route53_health_check(:db_master, {
          type: "TCP",
          fqdn: "db-master.internal.example.com",
          port: 5432,
          failure_threshold: 3,
          request_interval: 30
        })
        
        # Replica databases
        replica1_check = aws_route53_health_check(:db_replica1, {
          type: "TCP",
          fqdn: "db-replica1.internal.example.com",
          port: 5432,
          failure_threshold: 3,
          request_interval: 30
        })
        
        replica2_check = aws_route53_health_check(:db_replica2, {
          type: "TCP",
          fqdn: "db-replica2.internal.example.com",
          port: 5432,
          failure_threshold: 3,
          request_interval: 30
        })
        
        # Cluster health
        aws_route53_health_check(:db_cluster_health, {
          type: "CALCULATED",
          child_health_checks: ["hc-master", "hc-replica1", "hc-replica2"],
          child_health_threshold: 2,
          failure_threshold: 1,
          reference_name: "Database Cluster Health",
          tags: {
            Name: "db-cluster-health",
            Service: "postgresql",
            Environment: "production"
          }
        })
        
        synthesis
      end
      
      # Check individual database health checks exist
      expect(result["resource"]["aws_route53_health_check"]).to have_key("db_master")
      expect(result["resource"]["aws_route53_health_check"]).to have_key("db_replica1")
      expect(result["resource"]["aws_route53_health_check"]).to have_key("db_replica2")
      expect(result["resource"]["aws_route53_health_check"]).to have_key("db_cluster_health")
      
      cluster_health = result["resource"]["aws_route53_health_check"]["db_cluster_health"]
      expect(cluster_health["type"]).to eq("CALCULATED")
      expect(cluster_health["child_health_threshold"]).to eq(2)
    end
  end
  
  describe "default values synthesis" do
    it "synthesizes with default ports for HTTP/HTTPS" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:http_defaults, {
          type: "HTTP",
          fqdn: "example.com"
        })
        
        aws_route53_health_check(:https_defaults, {
          type: "HTTPS",
          fqdn: "secure.example.com"
        })
        
        synthesis
      end
      
      http_check = result["resource"]["aws_route53_health_check"]["http_defaults"]
      https_check = result["resource"]["aws_route53_health_check"]["https_defaults"]
      
      expect(http_check["port"]).to eq(80)
      expect(https_check["port"]).to eq(443)
      expect(https_check["enable_sni"]).to eq(true)
    end
    
    it "synthesizes with normalized resource paths" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:path_normalized, {
          type: "HTTP",
          fqdn: "example.com",
          resource_path: "health"  # Missing leading slash
        })
        
        synthesis
      end
      
      health_check = result["resource"]["aws_route53_health_check"]["path_normalized"]
      expect(health_check["resource_path"]).to eq("/health")
    end
  end
  
  describe "tag synthesis" do
    it "synthesizes comprehensive tags" do
      result = synthesizer.instance_eval do
        aws_route53_health_check(:tagged_health_check, {
          type: "HTTPS_STR_MATCH",
          fqdn: "app.example.com",
          port: 443,
          resource_path: "/health",
          search_string: "OK",
          tags: {
            Name: "production-app-health",
            Environment: "production",
            Application: "web-app",
            Team: "platform",
            CostCenter: "engineering",
            Service: "api",
            Criticality: "high",
            MonitoringTier: "tier1"
          }
        })
        
        synthesis
      end
      
      tags = result["resource"]["aws_route53_health_check"]["tagged_health_check"]["tags"]
      expect(tags).to include(
        Name: "production-app-health",
        Environment: "production",
        Application: "web-app",
        Team: "platform"
      )
    end
  end
end