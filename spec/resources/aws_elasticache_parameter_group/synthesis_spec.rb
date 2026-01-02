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
require 'pangea/resources/aws_elasticache_parameter_group/resource'
require 'pangea/resources/aws_elasticache_parameter_group/types'

RSpec.describe 'aws_elasticache_parameter_group synthesis' do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic Redis parameter group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:redis_params, {
          name: "my-redis-params",
          family: "redis7.x"
        })
      end

      result = synthesizer.synthesis
      param_group = result[:resource][:aws_elasticache_parameter_group][:redis_params]

      expect(param_group).to include(
        name: "my-redis-params",
        family: "redis7.x"
      )
    end

    it 'synthesizes basic Memcached parameter group' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:memcached_params, {
          name: "my-memcached-params",
          family: "memcached1.6"
        })
      end

      result = synthesizer.synthesis
      param_group = result[:resource][:aws_elasticache_parameter_group][:memcached_params]

      expect(param_group[:name]).to eq("my-memcached-params")
      expect(param_group[:family]).to eq("memcached1.6")
    end

    it 'synthesizes parameter group with description' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:described_params, {
          name: "described-params",
          family: "redis7.x",
          description: "Custom parameter group for production Redis"
        })
      end

      result = synthesizer.synthesis
      param_group = result[:resource][:aws_elasticache_parameter_group][:described_params]

      expect(param_group[:description]).to eq("Custom parameter group for production Redis")
    end

    it 'synthesizes parameter group with Redis parameters' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:redis_with_params, {
          name: "redis-optimized",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "allkeys-lru" },
            { name: "timeout", value: "300" },
            { name: "tcp-keepalive", value: "60" }
          ]
        })
      end

      result = synthesizer.synthesis
      param_group = result[:resource][:aws_elasticache_parameter_group][:redis_with_params]

      expect(param_group).to have_key(:parameter)
    end

    it 'synthesizes parameter group with Memcached parameters' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:memcached_with_params, {
          name: "memcached-optimized",
          family: "memcached1.6",
          parameters: [
            { name: "max_item_size", value: "134217728" },
            { name: "chunk_size_growth_factor", value: "1.25" }
          ]
        })
      end

      result = synthesizer.synthesis
      param_group = result[:resource][:aws_elasticache_parameter_group][:memcached_with_params]

      expect(param_group).to have_key(:parameter)
    end

    it 'synthesizes parameter group with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:tagged_params, {
          name: "tagged-params",
          family: "redis7.x",
          tags: { Name: "production-params", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      param_group = result[:resource][:aws_elasticache_parameter_group][:tagged_params]

      expect(param_group).to have_key(:tags)
      expect(param_group[:tags][:Name]).to eq("production-params")
      expect(param_group[:tags][:Environment]).to eq("production")
    end

    it 'synthesizes parameter group for different Redis versions' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_parameter_group(:redis6_params, {
          name: "redis6-params",
          family: "redis6.x"
        })

        aws_elasticache_parameter_group(:redis7_params, {
          name: "redis7-params",
          family: "redis7.x"
        })
      end

      result = synthesizer.synthesis
      param_groups = result[:resource][:aws_elasticache_parameter_group]

      expect(param_groups[:redis6_params][:family]).to eq("redis6.x")
      expect(param_groups[:redis7_params][:family]).to eq("redis7.x")
    end

    it 'synthesizes multiple parameter groups' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_parameter_group(:redis_performance, {
          name: "redis-performance",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "allkeys-lru" }
          ]
        })

        aws_elasticache_parameter_group(:redis_persistence, {
          name: "redis-persistence",
          family: "redis7.x",
          parameters: [
            { name: "save", value: "900 1 300 10 60 10000" }
          ]
        })

        aws_elasticache_parameter_group(:memcached_high_throughput, {
          name: "memcached-high-throughput",
          family: "memcached1.6",
          parameters: [
            { name: "max_simultaneous_connections", value: "65000" }
          ]
        })
      end

      result = synthesizer.synthesis
      param_groups = result[:resource][:aws_elasticache_parameter_group]

      expect(param_groups).to have_key(:redis_performance)
      expect(param_groups).to have_key(:redis_persistence)
      expect(param_groups).to have_key(:memcached_high_throughput)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:test, {
          name: "test-params",
          family: "redis7.x"
        })
      end

      expect(ref.id).to eq("${aws_elasticache_parameter_group.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_elasticache_parameter_group.test.name}")
      expect(ref.outputs[:arn]).to eq("${aws_elasticache_parameter_group.test.arn}")
      expect(ref.outputs[:family]).to eq("${aws_elasticache_parameter_group.test.family}")
    end

    it 'provides computed properties' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:computed_test, {
          name: "computed-test",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "allkeys-lru" },
            { name: "timeout", value: "300" }
          ]
        })
      end

      expect(ref.computed_properties[:is_redis_family]).to eq(true)
      expect(ref.computed_properties[:is_memcached_family]).to eq(false)
      expect(ref.computed_properties[:parameter_count]).to eq(2)
    end
  end

  describe 'resource composition' do
    it 'creates parameter group for use with cluster' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        param_group_ref = aws_elasticache_parameter_group(:cluster_params, {
          name: "cluster-params",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "allkeys-lru" }
          ]
        })

        aws_elasticache_cluster(:redis_with_params, {
          cluster_id: "redis-with-params",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          parameter_group_name: "cluster-params"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource]).to have_key(:aws_elasticache_parameter_group)
      expect(result[:resource]).to have_key(:aws_elasticache_cluster)
      expect(result[:resource][:aws_elasticache_cluster][:redis_with_params][:parameter_group_name]).to eq("cluster-params")
    end

    it 'creates multiple parameter groups for different environments' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_parameter_group(:dev_params, {
          name: "dev-redis-params",
          family: "redis7.x",
          tags: { Environment: "development" }
        })

        aws_elasticache_parameter_group(:prod_params, {
          name: "prod-redis-params",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "volatile-lru" },
            { name: "reserved-memory-percent", value: "25" }
          ],
          tags: { Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      param_groups = result[:resource][:aws_elasticache_parameter_group]

      expect(param_groups[:dev_params][:tags][:Environment]).to eq("development")
      expect(param_groups[:prod_params][:tags][:Environment]).to eq("production")
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_parameter_group(:validation_test, {
          name: "validation-test",
          family: "redis7.x"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_elasticache_parameter_group]).to be_a(Hash)
      expect(result[:resource][:aws_elasticache_parameter_group][:validation_test]).to be_a(Hash)

      param_group_config = result[:resource][:aws_elasticache_parameter_group][:validation_test]
      expect(param_group_config).to have_key(:name)
      expect(param_group_config).to have_key(:family)
      expect(param_group_config[:name]).to be_a(String)
      expect(param_group_config[:family]).to be_a(String)
    end
  end
end
