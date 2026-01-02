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
require 'pangea/resources/aws_elasticache_cluster/resource'
require 'pangea/resources/aws_elasticache_cluster/types'

RSpec.describe 'aws_elasticache_cluster synthesis' do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic Redis cluster' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:redis_cache, {
          cluster_id: "my-redis-cluster",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:redis_cache]

      expect(cluster).to include(
        cluster_id: "my-redis-cluster",
        engine: "redis",
        node_type: "cache.t4g.micro",
        num_cache_nodes: 1
      )
    end

    it 'synthesizes basic Memcached cluster' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:memcached_cache, {
          cluster_id: "my-memcached-cluster",
          engine: "memcached",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 2
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:memcached_cache]

      expect(cluster[:cluster_id]).to eq("my-memcached-cluster")
      expect(cluster[:engine]).to eq("memcached")
      expect(cluster[:num_cache_nodes]).to eq(2)
    end

    it 'synthesizes Redis cluster with encryption' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:encrypted_redis, {
          cluster_id: "encrypted-redis",
          engine: "redis",
          node_type: "cache.t4g.small",
          num_cache_nodes: 1,
          at_rest_encryption_enabled: true,
          transit_encryption_enabled: true
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:encrypted_redis]

      expect(cluster[:at_rest_encryption_enabled]).to eq(true)
      expect(cluster[:transit_encryption_enabled]).to eq(true)
    end

    it 'synthesizes Redis cluster with snapshot configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:redis_with_snapshot, {
          cluster_id: "redis-with-snapshots",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          snapshot_retention_limit: 7,
          snapshot_window: "05:00-09:00"
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:redis_with_snapshot]

      expect(cluster[:snapshot_retention_limit]).to eq(7)
      expect(cluster[:snapshot_window]).to eq("05:00-09:00")
    end

    it 'synthesizes cluster with network configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:networked_redis, {
          cluster_id: "networked-redis",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          subnet_group_name: "my-subnet-group",
          security_group_ids: ["sg-12345678", "sg-87654321"]
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:networked_redis]

      expect(cluster[:subnet_group_name]).to eq("my-subnet-group")
      expect(cluster[:security_group_ids]).to eq(["sg-12345678", "sg-87654321"])
    end

    it 'synthesizes cluster with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:tagged_cluster, {
          cluster_id: "tagged-cluster",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          tags: { Name: "my-cache", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:tagged_cluster]

      expect(cluster).to have_key(:tags)
      expect(cluster[:tags][:Name]).to eq("my-cache")
      expect(cluster[:tags][:Environment]).to eq("production")
    end

    it 'synthesizes cluster with maintenance window' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:maintenance_cluster, {
          cluster_id: "maintenance-cluster",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          maintenance_window: "sun:05:00-sun:09:00"
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:maintenance_cluster]

      expect(cluster[:maintenance_window]).to eq("sun:05:00-sun:09:00")
    end

    it 'synthesizes cluster with parameter group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:parameterized_cluster, {
          cluster_id: "parameterized-cluster",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          parameter_group_name: "custom-redis-params",
          engine_version: "7.0"
        })
      end

      result = synthesizer.synthesis
      cluster = result[:resource][:aws_elasticache_cluster][:parameterized_cluster]

      expect(cluster[:parameter_group_name]).to eq("custom-redis-params")
      expect(cluster[:engine_version]).to eq("7.0")
    end

    it 'synthesizes multiple clusters' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_cluster(:redis_primary, {
          cluster_id: "redis-primary",
          engine: "redis",
          node_type: "cache.m6g.large",
          num_cache_nodes: 1
        })

        aws_elasticache_cluster(:memcached_session, {
          cluster_id: "memcached-session",
          engine: "memcached",
          node_type: "cache.t4g.small",
          num_cache_nodes: 3
        })
      end

      result = synthesizer.synthesis
      clusters = result[:resource][:aws_elasticache_cluster]

      expect(clusters).to have_key(:redis_primary)
      expect(clusters).to have_key(:memcached_session)
      expect(clusters[:redis_primary][:engine]).to eq("redis")
      expect(clusters[:memcached_session][:engine]).to eq("memcached")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:test, {
          cluster_id: "test-cluster",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1
        })
      end

      expect(ref.id).to eq("${aws_elasticache_cluster.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_elasticache_cluster.test.arn}")
      expect(ref.outputs[:cluster_address]).to eq("${aws_elasticache_cluster.test.cluster_address}")
      expect(ref.outputs[:configuration_endpoint]).to eq("${aws_elasticache_cluster.test.configuration_endpoint}")
      expect(ref.outputs[:port]).to eq("${aws_elasticache_cluster.test.port}")
    end

    it 'provides computed properties for Redis cluster' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:redis_test, {
          cluster_id: "redis-test",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1
        })
      end

      expect(ref.is_redis?).to eq(true)
      expect(ref.is_memcached?).to eq(false)
      expect(ref.supports_encryption?).to eq(true)
      expect(ref.supports_backup?).to eq(true)
    end

    it 'provides computed properties for Memcached cluster' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:memcached_test, {
          cluster_id: "memcached-test",
          engine: "memcached",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 2
        })
      end

      expect(ref.is_redis?).to eq(false)
      expect(ref.is_memcached?).to eq(true)
      expect(ref.supports_encryption?).to eq(false)
      expect(ref.supports_backup?).to eq(false)
    end
  end

  describe 'resource composition' do
    it 'creates cluster with subnet group reference' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        subnet_group_ref = aws_elasticache_subnet_group(:cache_subnets, {
          name: "cache-subnet-group",
          subnet_ids: ["subnet-12345678", "subnet-87654321"]
        })

        aws_elasticache_cluster(:composed_cluster, {
          cluster_id: "composed-cluster",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          subnet_group_name: "cache-subnet-group"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource]).to have_key(:aws_elasticache_subnet_group)
      expect(result[:resource]).to have_key(:aws_elasticache_cluster)
      expect(result[:resource][:aws_elasticache_cluster][:composed_cluster][:subnet_group_name]).to eq("cache-subnet-group")
    end

    it 'creates cluster with parameter group reference' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_parameter_group(:redis_params, {
          name: "custom-redis-params",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "allkeys-lru" }
          ]
        })

        aws_elasticache_cluster(:cluster_with_params, {
          cluster_id: "cluster-with-params",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          parameter_group_name: "custom-redis-params"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource]).to have_key(:aws_elasticache_parameter_group)
      expect(result[:resource]).to have_key(:aws_elasticache_cluster)
      expect(result[:resource][:aws_elasticache_cluster][:cluster_with_params][:parameter_group_name]).to eq("custom-redis-params")
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_cluster(:validation_test, {
          cluster_id: "validation-test",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_elasticache_cluster]).to be_a(Hash)
      expect(result[:resource][:aws_elasticache_cluster][:validation_test]).to be_a(Hash)

      cluster_config = result[:resource][:aws_elasticache_cluster][:validation_test]
      expect(cluster_config).to have_key(:cluster_id)
      expect(cluster_config[:cluster_id]).to be_a(String)
    end
  end
end
