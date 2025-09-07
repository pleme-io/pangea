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
require 'json'

# Load aws_elasticache_cluster resource and terraform-synthesizer for testing
require 'pangea/resources/aws_elasticache_cluster/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_elasticache_cluster terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test basic Redis cluster synthesis
  it "synthesizes basic Redis cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:basic_redis, {
        cluster_id: "my-redis-cluster",
        engine: "redis",
        node_type: "cache.t4g.micro"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :basic_redis)
    
    expect(cluster_config[:cluster_id]).to eq("my-redis-cluster")
    expect(cluster_config[:engine]).to eq("redis")
    expect(cluster_config[:node_type]).to eq("cache.t4g.micro")
    expect(cluster_config[:num_cache_nodes]).to eq(1)
    
    # Should not include optional fields
    expect(cluster_config).not_to have_key(:engine_version)
    expect(cluster_config).not_to have_key(:at_rest_encryption_enabled)
  end
  
  # Test basic Memcached cluster synthesis
  it "synthesizes basic Memcached cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:basic_memcached, {
        cluster_id: "my-memcached-cluster",
        engine: "memcached",
        node_type: "cache.t3.small",
        num_cache_nodes: 3
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :basic_memcached)
    
    expect(cluster_config[:cluster_id]).to eq("my-memcached-cluster")
    expect(cluster_config[:engine]).to eq("memcached")
    expect(cluster_config[:node_type]).to eq("cache.t3.small")
    expect(cluster_config[:num_cache_nodes]).to eq(3)
  end
  
  # Test encrypted Redis cluster synthesis
  it "synthesizes encrypted Redis cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:encrypted_redis, {
        cluster_id: "secure-redis",
        engine: "redis",
        node_type: "cache.r6g.large",
        engine_version: "7.0",
        at_rest_encryption_enabled: true,
        transit_encryption_enabled: true,
        auth_token: "mysupersecrettoken123!"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :encrypted_redis)
    
    expect(cluster_config[:at_rest_encryption_enabled]).to eq(true)
    expect(cluster_config[:transit_encryption_enabled]).to eq(true)
    expect(cluster_config[:auth_token]).to eq("mysupersecrettoken123!")
  end
  
  # Test Redis with snapshots synthesis
  it "synthesizes Redis with snapshots correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:redis_snapshots, {
        cluster_id: "redis-with-backups",
        engine: "redis",
        node_type: "cache.m6g.xlarge",
        snapshot_retention_limit: 7,
        snapshot_window: "03:00-05:00",
        final_snapshot_identifier: "redis-final-backup"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :redis_snapshots)
    
    expect(cluster_config[:snapshot_retention_limit]).to eq(7)
    expect(cluster_config[:snapshot_window]).to eq("03:00-05:00")
    expect(cluster_config[:final_snapshot_identifier]).to eq("redis-final-backup")
  end
  
  # Test multi-AZ Memcached synthesis
  it "synthesizes multi-AZ Memcached correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:multi_az_memcached, {
        cluster_id: "memcached-multi-az",
        engine: "memcached",
        node_type: "cache.m5.large",
        num_cache_nodes: 4,
        preferred_availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :multi_az_memcached)
    
    expect(cluster_config[:num_cache_nodes]).to eq(4)
    expect(cluster_config[:preferred_availability_zones]).to eq(["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"])
  end
  
  # Test cluster with network configuration synthesis
  it "synthesizes cluster with network configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:networked_cluster, {
        cluster_id: "vpc-redis",
        engine: "redis",
        node_type: "cache.r5.xlarge",
        subnet_group_name: "my-cache-subnet-group",
        security_group_ids: ["sg-12345678", "sg-87654321"],
        availability_zone: "us-east-1a"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :networked_cluster)
    
    expect(cluster_config[:subnet_group_name]).to eq("my-cache-subnet-group")
    expect(cluster_config[:security_group_ids]).to eq(["sg-12345678", "sg-87654321"])
    expect(cluster_config[:availability_zone]).to eq("us-east-1a")
  end
  
  # Test cluster with maintenance window synthesis
  it "synthesizes cluster with maintenance configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:maintained_cluster, {
        cluster_id: "maintained-redis",
        engine: "redis",
        node_type: "cache.t4g.medium",
        maintenance_window: "sun:05:00-sun:07:00",
        notification_topic_arn: "arn:aws:sns:us-east-1:123456789012:cache-notifications",
        auto_minor_version_upgrade: false,
        apply_immediately: true
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :maintained_cluster)
    
    expect(cluster_config[:maintenance_window]).to eq("sun:05:00-sun:07:00")
    expect(cluster_config[:notification_topic_arn]).to eq("arn:aws:sns:us-east-1:123456789012:cache-notifications")
    expect(cluster_config[:auto_minor_version_upgrade]).to eq(false)
    expect(cluster_config[:apply_immediately]).to eq(true)
  end
  
  # Test cluster with log delivery synthesis
  it "synthesizes cluster with log delivery correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:logged_cluster, {
        cluster_id: "logged-redis",
        engine: "redis",
        node_type: "cache.r6g.large",
        log_delivery_configuration: [
          {
            destination: "/aws/elasticache/redis/slow-log",
            destination_type: "cloudwatch-logs",
            log_format: "json",
            log_type: "slow-log"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :logged_cluster)
    
    # Log delivery configuration should be included as a block
    expect(cluster_config).to have_key(:log_delivery_configuration)
  end
  
  # Test cluster with tags synthesis
  it "synthesizes cluster with tags correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:tagged_cluster, {
        cluster_id: "tagged-redis",
        engine: "redis",
        node_type: "cache.t4g.small",
        tags: {
          Environment: "production",
          Application: "web-api",
          Team: "platform",
          CostCenter: "engineering"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :tagged_cluster)
    
    expect(cluster_config[:tags]).to be_a(Hash)
    expect(cluster_config[:tags][:Environment]).to eq("production")
    expect(cluster_config[:tags][:Application]).to eq("web-api")
    expect(cluster_config[:tags][:Team]).to eq("platform")
    expect(cluster_config[:tags][:CostCenter]).to eq("engineering")
  end
  
  # Test Redis session store pattern synthesis
  it "synthesizes Redis session store pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:session_store, {
        cluster_id: "app-sessions",
        engine: "redis",
        node_type: "cache.r6g.xlarge",
        engine_version: "7.0",
        parameter_group_name: "redis7-session-params",
        subnet_group_name: "app-cache-subnets",
        at_rest_encryption_enabled: true,
        transit_encryption_enabled: true,
        auth_token: "session-secret-key-123!",
        snapshot_retention_limit: 1,
        tags: {
          Purpose: "session-storage",
          DataType: "ephemeral",
          Application: "web-app"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :session_store)
    
    expect(cluster_config[:cluster_id]).to eq("app-sessions")
    expect(cluster_config[:node_type]).to eq("cache.r6g.xlarge")
    expect(cluster_config[:at_rest_encryption_enabled]).to eq(true)
    expect(cluster_config[:transit_encryption_enabled]).to eq(true)
    expect(cluster_config[:snapshot_retention_limit]).to eq(1)
  end
  
  # Test Memcached distributed cache pattern synthesis
  it "synthesizes Memcached distributed cache pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:distributed_cache, {
        cluster_id: "app-cache-cluster",
        engine: "memcached",
        node_type: "cache.m6g.xlarge",
        engine_version: "1.6.17",
        num_cache_nodes: 6,
        parameter_group_name: "memcached-params",
        subnet_group_name: "app-cache-subnets",
        preferred_availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"] * 2,
        tags: {
          Purpose: "distributed-cache",
          DataType: "temporary",
          Application: "api-service"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :distributed_cache)
    
    expect(cluster_config[:engine]).to eq("memcached")
    expect(cluster_config[:num_cache_nodes]).to eq(6)
    expect(cluster_config[:preferred_availability_zones]).to have(6).items
  end
  
  # Test Redis analytics cache pattern synthesis
  it "synthesizes Redis analytics cache pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:analytics_cache, {
        cluster_id: "analytics-redis-cluster",
        engine: "redis",
        node_type: "cache.r5.2xlarge",
        engine_version: "7.0",
        parameter_group_name: "redis7-analytics",
        subnet_group_name: "analytics-cache-subnets",
        snapshot_retention_limit: 14,
        snapshot_window: "02:00-04:00",
        maintenance_window: "mon:03:00-mon:05:00",
        auto_minor_version_upgrade: false,
        tags: {
          Purpose: "analytics-cache",
          DataType: "time-series",
          Team: "data-engineering",
          RetentionDays: "14"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :analytics_cache)
    
    expect(cluster_config[:node_type]).to eq("cache.r5.2xlarge")
    expect(cluster_config[:snapshot_retention_limit]).to eq(14)
    expect(cluster_config[:maintenance_window]).to eq("mon:03:00-mon:05:00")
    expect(cluster_config[:tags][:Purpose]).to eq("analytics-cache")
  end
  
  # Test minimal Redis cluster synthesis
  it "synthesizes minimal Redis cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:minimal_redis, {
        cluster_id: "minimal",
        engine: "redis",
        node_type: "cache.t4g.micro"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :minimal_redis)
    
    expect(cluster_config[:cluster_id]).to eq("minimal")
    expect(cluster_config[:engine]).to eq("redis")
    expect(cluster_config[:node_type]).to eq("cache.t4g.micro")
    expect(cluster_config[:num_cache_nodes]).to eq(1)
    
    # Optional fields should not be present
    expect(cluster_config).not_to have_key(:engine_version)
    expect(cluster_config).not_to have_key(:parameter_group_name)
    expect(cluster_config).not_to have_key(:subnet_group_name)
    expect(cluster_config).not_to have_key(:security_group_ids)
    expect(cluster_config).not_to have_key(:snapshot_retention_limit)
    expect(cluster_config).not_to have_key(:tags)
  end
  
  # Test Redis with restore from snapshot synthesis
  it "synthesizes Redis restore from snapshot correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_elasticache_cluster(:restored_redis, {
        cluster_id: "restored-from-snapshot",
        engine: "redis",
        node_type: "cache.r6g.large",
        snapshot_arns: ["arn:aws:s3:::my-bucket/redis-backup.rdb"],
        snapshot_name: "production-backup-2024-01-15",
        tags: {
          RestoredFrom: "production-backup",
          RestoredDate: "2024-01-16"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :restored_redis)
    
    expect(cluster_config[:snapshot_arns]).to eq(["arn:aws:s3:::my-bucket/redis-backup.rdb"])
    expect(cluster_config[:snapshot_name]).to eq("production-backup-2024-01-15")
    expect(cluster_config[:tags][:RestoredFrom]).to eq("production-backup")
  end
  
  # Test high-performance Redis configuration synthesis
  it "synthesizes high-performance Redis configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Using the ElastiCacheConfigs helper
      config = Pangea::Resources::AWS::Types::ElastiCacheConfigs.redis_high_performance(
        node_type: "cache.r6g.4xlarge"
      )
      
      aws_elasticache_cluster(:high_perf_redis, config.merge(
        cluster_id: "high-performance-redis",
        subnet_group_name: "perf-cache-subnets",
        parameter_group_name: "redis7-high-performance"
      ))
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_elasticache_cluster, :high_perf_redis)
    
    expect(cluster_config[:node_type]).to eq("cache.r6g.4xlarge")
    expect(cluster_config[:at_rest_encryption_enabled]).to eq(true)
    expect(cluster_config[:transit_encryption_enabled]).to eq(true)
    expect(cluster_config[:snapshot_retention_limit]).to eq(7)
    expect(cluster_config[:auto_minor_version_upgrade]).to eq(false)
  end
end