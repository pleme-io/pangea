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

# Load aws_elasticache_cluster resource and types for testing
require 'pangea/resources/aws_elasticache_cluster/resource'
require 'pangea/resources/aws_elasticache_cluster/types'

RSpec.describe "aws_elasticache_cluster resource function" do
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
  
  describe "ElastiCacheClusterAttributes validation" do
    it "accepts minimal Redis configuration" do
      cluster = Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
        cluster_id: "my-redis-cluster",
        engine: "redis",
        node_type: "cache.t4g.micro"
      })
      
      expect(cluster.cluster_id).to eq("my-redis-cluster")
      expect(cluster.engine).to eq("redis")
      expect(cluster.node_type).to eq("cache.t4g.micro")
      expect(cluster.num_cache_nodes).to eq(1)
      expect(cluster.port).to eq(6379)
    end
    
    it "accepts minimal Memcached configuration" do
      cluster = Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
        cluster_id: "my-memcached-cluster",
        engine: "memcached",
        node_type: "cache.t3.micro",
        num_cache_nodes: 3
      })
      
      expect(cluster.engine).to eq("memcached")
      expect(cluster.num_cache_nodes).to eq(3)
      expect(cluster.port).to eq(11211)
    end
    
    it "validates engine type" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "invalid",
          node_type: "cache.t4g.micro"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates node type" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "redis",
          node_type: "invalid.instance"
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates Redis single node constraint" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 5
        })
      }.to raise_error(Dry::Struct::Error, /Redis clusters should use num_cache_nodes=1/)
    end
    
    it "validates auth token requires transit encryption" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "redis",
          node_type: "cache.t4g.micro",
          auth_token: "mysecrettoken",
          transit_encryption_enabled: false
        })
      }.to raise_error(Dry::Struct::Error, /Auth token requires transit_encryption_enabled=true/)
    end
    
    it "validates snapshot features are Redis-only" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "memcached",
          node_type: "cache.t3.micro",
          snapshot_retention_limit: 5
        })
      }.to raise_error(Dry::Struct::Error, /Snapshot configuration is only available for Redis/)
    end
    
    it "validates encryption is Redis-only" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "memcached",
          node_type: "cache.t3.micro",
          at_rest_encryption_enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Encryption is only available for Redis/)
    end
    
    it "validates availability zone configuration" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "redis",
          node_type: "cache.t4g.micro",
          availability_zone: "us-east-1a",
          preferred_availability_zones: ["us-east-1b", "us-east-1c"]
        })
      }.to raise_error(Dry::Struct::Error, /Cannot specify both availability_zone and preferred_availability_zones/)
    end
    
    it "validates multi-AZ Memcached requirements" do
      expect {
        Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
          cluster_id: "test",
          engine: "memcached",
          node_type: "cache.t3.micro",
          num_cache_nodes: 1,
          preferred_availability_zones: ["us-east-1a", "us-east-1b"]
        })
      }.to raise_error(Dry::Struct::Error, /Multi-AZ deployment requires at least 2 cache nodes/)
    end
  end
  
  describe "computed properties" do
    let(:redis_cluster) do
      Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
        cluster_id: "redis-test",
        engine: "redis",
        node_type: "cache.r6g.large",
        engine_version: "7.0"
      })
    end
    
    let(:memcached_cluster) do
      Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
        cluster_id: "memcached-test",
        engine: "memcached",
        node_type: "cache.m5.xlarge",
        num_cache_nodes: 3
      })
    end
    
    it "provides engine detection methods" do
      expect(redis_cluster.is_redis?).to eq(true)
      expect(redis_cluster.is_memcached?).to eq(false)
      expect(memcached_cluster.is_redis?).to eq(false)
      expect(memcached_cluster.is_memcached?).to eq(true)
    end
    
    it "provides default port based on engine" do
      expect(redis_cluster.default_port).to eq(6379)
      expect(memcached_cluster.default_port).to eq(11211)
    end
    
    it "provides engine capability detection" do
      expect(redis_cluster.supports_encryption?).to eq(true)
      expect(redis_cluster.supports_backup?).to eq(true)
      expect(redis_cluster.supports_auth?).to eq(true)
      
      expect(memcached_cluster.supports_encryption?).to eq(false)
      expect(memcached_cluster.supports_backup?).to eq(false)
      expect(memcached_cluster.supports_auth?).to eq(false)
    end
    
    it "detects encryption support by version" do
      old_redis = Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
        cluster_id: "old-redis",
        engine: "redis",
        node_type: "cache.t3.micro",
        engine_version: "3.2.4"
      })
      expect(old_redis.engine_supports_encryption?).to eq(false)
      
      new_redis = Pangea::Resources::AWS::Types::ElastiCacheClusterAttributes.new({
        cluster_id: "new-redis",
        engine: "redis",
        node_type: "cache.t3.micro",
        engine_version: "3.2.6"
      })
      expect(new_redis.engine_supports_encryption?).to eq(true)
    end
    
    it "provides cost estimation" do
      expect(redis_cluster.estimated_monthly_cost).to match(/~\$\d+\.\d+\/month/)
      expect(memcached_cluster.estimated_monthly_cost).to match(/~\$\d+\.\d+\/month/)
    end
  end
  
  describe "aws_elasticache_cluster function" do
    it "creates basic Redis cluster" do
      result = test_instance.aws_elasticache_cluster(:redis_cache, {
        cluster_id: "my-redis",
        engine: "redis",
        node_type: "cache.t4g.micro"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_elasticache_cluster')
      expect(result.name).to eq(:redis_cache)
      expect(result.cluster_address).to eq("${aws_elasticache_cluster.redis_cache.cluster_address}")
    end
    
    it "creates basic Memcached cluster" do
      result = test_instance.aws_elasticache_cluster(:memcached_cache, {
        cluster_id: "my-memcached",
        engine: "memcached",
        node_type: "cache.t3.small",
        num_cache_nodes: 2
      })
      
      expect(result.resource_attributes[:engine]).to eq("memcached")
      expect(result.resource_attributes[:num_cache_nodes]).to eq(2)
      expect(result.configuration_endpoint).to eq("${aws_elasticache_cluster.memcached_cache.configuration_endpoint}")
    end
    
    it "creates encrypted Redis cluster" do
      result = test_instance.aws_elasticache_cluster(:secure_redis, {
        cluster_id: "secure-redis",
        engine: "redis",
        node_type: "cache.r6g.large",
        at_rest_encryption_enabled: true,
        transit_encryption_enabled: true,
        auth_token: "mysupersecrettoken123!"
      })
      
      expect(result.resource_attributes[:at_rest_encryption_enabled]).to eq(true)
      expect(result.resource_attributes[:transit_encryption_enabled]).to eq(true)
      expect(result.supports_encryption?).to eq(true)
    end
    
    it "creates Redis cluster with snapshots" do
      result = test_instance.aws_elasticache_cluster(:redis_with_backups, {
        cluster_id: "redis-backups",
        engine: "redis",
        node_type: "cache.m6g.large",
        snapshot_retention_limit: 7,
        snapshot_window: "03:00-05:00",
        final_snapshot_identifier: "redis-final-snapshot"
      })
      
      expect(result.resource_attributes[:snapshot_retention_limit]).to eq(7)
      expect(result.resource_attributes[:snapshot_window]).to eq("03:00-05:00")
      expect(result.supports_backup?).to eq(true)
    end
    
    it "creates multi-AZ Memcached cluster" do
      result = test_instance.aws_elasticache_cluster(:memcached_multi_az, {
        cluster_id: "memcached-az",
        engine: "memcached",
        node_type: "cache.m5.large",
        num_cache_nodes: 4,
        preferred_availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
      })
      
      expect(result.resource_attributes[:num_cache_nodes]).to eq(4)
      expect(result.resource_attributes[:preferred_availability_zones]).to have(4).items
    end
    
    it "creates cluster with custom configuration" do
      result = test_instance.aws_elasticache_cluster(:custom_cluster, {
        cluster_id: "custom-config",
        engine: "redis",
        node_type: "cache.r5.xlarge",
        engine_version: "6.2",
        parameter_group_name: "custom-redis62-params",
        subnet_group_name: "my-subnet-group",
        security_group_ids: ["sg-12345678", "sg-87654321"],
        maintenance_window: "sun:05:00-sun:07:00",
        auto_minor_version_upgrade: false
      })
      
      expect(result.resource_attributes[:engine_version]).to eq("6.2")
      expect(result.resource_attributes[:parameter_group_name]).to eq("custom-redis62-params")
      expect(result.resource_attributes[:security_group_ids]).to have(2).items
      expect(result.resource_attributes[:auto_minor_version_upgrade]).to eq(false)
    end
    
    it "creates cluster with log delivery" do
      result = test_instance.aws_elasticache_cluster(:logged_cluster, {
        cluster_id: "logged-redis",
        engine: "redis",
        node_type: "cache.t4g.medium",
        log_delivery_configuration: [
          {
            destination: "my-log-group",
            destination_type: "cloudwatch-logs",
            log_format: "json",
            log_type: "slow-log"
          }
        ]
      })
      
      expect(result.resource_attributes[:log_delivery_configuration]).to have(1).item
      expect(result.resource_attributes[:log_delivery_configuration].first[:log_type]).to eq("slow-log")
    end
    
    it "creates cluster with tags" do
      result = test_instance.aws_elasticache_cluster(:tagged_cluster, {
        cluster_id: "tagged-redis",
        engine: "redis",
        node_type: "cache.t4g.micro",
        tags: {
          Environment: "production",
          Application: "web-app",
          Team: "platform"
        }
      })
      
      expect(result.resource_attributes[:tags]).to have(3).items
      expect(result.resource_attributes[:tags][:Environment]).to eq("production")
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_elasticache_cluster(:test, {
        cluster_id: "test-cluster",
        engine: "redis",
        node_type: "cache.t4g.micro"
      })
      
      expect(result.id).to eq("${aws_elasticache_cluster.test.id}")
      expect(result.arn).to eq("${aws_elasticache_cluster.test.arn}")
      expect(result.cluster_address).to eq("${aws_elasticache_cluster.test.cluster_address}")
      expect(result.configuration_endpoint).to eq("${aws_elasticache_cluster.test.configuration_endpoint}")
      expect(result.port).to eq("${aws_elasticache_cluster.test.port}")
      expect(result.cache_nodes).to eq("${aws_elasticache_cluster.test.cache_nodes}")
      expect(result.engine_version_actual).to eq("${aws_elasticache_cluster.test.engine_version_actual}")
      expect(result.tags_all).to eq("${aws_elasticache_cluster.test.tags_all}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_elasticache_cluster(:test, {
        cluster_id: "test-redis",
        engine: "redis",
        node_type: "cache.r6g.large",
        at_rest_encryption_enabled: true
      })
      
      expect(result.is_redis?).to eq(true)
      expect(result.is_memcached?).to eq(false)
      expect(result.default_port).to eq(6379)
      expect(result.supports_encryption?).to eq(true)
      expect(result.supports_backup?).to eq(true)
      expect(result.supports_auth?).to eq(true)
      expect(result.engine_supports_encryption?).to eq(true)
      expect(result.is_cluster_mode?).to eq(false)
      expect(result.estimated_monthly_cost).to match(/~\$/)
    end
  end
  
  describe "ElastiCacheConfigs helper module" do
    it "provides default Redis configuration" do
      config = Pangea::Resources::AWS::Types::ElastiCacheConfigs.redis
      
      expect(config[:engine]).to eq("redis")
      expect(config[:engine_version]).to eq("7.0")
      expect(config[:node_type]).to eq("cache.t4g.micro")
      expect(config[:at_rest_encryption_enabled]).to eq(true)
      expect(config[:transit_encryption_enabled]).to eq(true)
    end
    
    it "provides default Memcached configuration" do
      config = Pangea::Resources::AWS::Types::ElastiCacheConfigs.memcached
      
      expect(config[:engine]).to eq("memcached")
      expect(config[:engine_version]).to eq("1.6.17")
      expect(config[:num_cache_nodes]).to eq(2)
      expect(config[:port]).to eq(11211)
    end
    
    it "provides high-performance Redis configuration" do
      config = Pangea::Resources::AWS::Types::ElastiCacheConfigs.redis_high_performance
      
      expect(config[:node_type]).to eq("cache.r6g.large")
      expect(config[:snapshot_retention_limit]).to eq(7)
      expect(config[:auto_minor_version_upgrade]).to eq(false)
    end
  end
  
  describe "engine-specific patterns" do
    it "creates Redis cluster for session storage" do
      result = test_instance.aws_elasticache_cluster(:session_store, {
        cluster_id: "app-sessions",
        engine: "redis",
        node_type: "cache.r6g.xlarge",
        engine_version: "7.0",
        at_rest_encryption_enabled: true,
        transit_encryption_enabled: true,
        auth_token: "session-auth-token-123!",
        snapshot_retention_limit: 1,
        tags: {
          Purpose: "session-storage",
          DataType: "ephemeral"
        }
      })
      
      expect(result.is_redis?).to eq(true)
      expect(result.supports_auth?).to eq(true)
      expect(result.resource_attributes[:tags][:Purpose]).to eq("session-storage")
    end
    
    it "creates Memcached cluster for object caching" do
      result = test_instance.aws_elasticache_cluster(:object_cache, {
        cluster_id: "app-cache",
        engine: "memcached",
        node_type: "cache.m6g.xlarge",
        num_cache_nodes: 6,
        preferred_availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"] * 2,
        tags: {
          Purpose: "object-caching",
          DataType: "temporary"
        }
      })
      
      expect(result.is_memcached?).to eq(true)
      expect(result.resource_attributes[:num_cache_nodes]).to eq(6)
    end
    
    it "creates Redis cluster for real-time analytics" do
      result = test_instance.aws_elasticache_cluster(:analytics_cache, {
        cluster_id: "analytics-redis",
        engine: "redis",
        node_type: "cache.r5.2xlarge",
        engine_version: "7.0",
        snapshot_retention_limit: 14,
        snapshot_window: "02:00-04:00",
        maintenance_window: "mon:03:00-mon:05:00",
        tags: {
          Purpose: "analytics",
          DataType: "time-series"
        }
      })
      
      expect(result.supports_backup?).to eq(true)
      expect(result.resource_attributes[:snapshot_retention_limit]).to eq(14)
    end
  end
end