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
require 'pangea/resources/aws_elasticache_subnet_group/resource'
require 'pangea/resources/aws_elasticache_subnet_group/types'

RSpec.describe 'aws_elasticache_subnet_group synthesis' do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic subnet group with single subnet' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:cache_subnets, {
          name: "cache-subnet-group",
          subnet_ids: ["subnet-12345678"]
        })
      end

      result = synthesizer.synthesis
      subnet_group = result[:resource][:aws_elasticache_subnet_group][:cache_subnets]

      expect(subnet_group).to include(
        name: "cache-subnet-group",
        subnet_ids: ["subnet-12345678"]
      )
    end

    it 'synthesizes subnet group with multiple subnets for multi-az' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:multi_az_subnets, {
          name: "multi-az-subnet-group",
          subnet_ids: ["subnet-12345678", "subnet-87654321", "subnet-abcdef12"]
        })
      end

      result = synthesizer.synthesis
      subnet_group = result[:resource][:aws_elasticache_subnet_group][:multi_az_subnets]

      expect(subnet_group[:subnet_ids]).to eq(["subnet-12345678", "subnet-87654321", "subnet-abcdef12"])
    end

    it 'synthesizes subnet group with description' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:described_subnets, {
          name: "described-subnet-group",
          subnet_ids: ["subnet-12345678"],
          description: "Subnet group for production cache clusters"
        })
      end

      result = synthesizer.synthesis
      subnet_group = result[:resource][:aws_elasticache_subnet_group][:described_subnets]

      expect(subnet_group[:description]).to eq("Subnet group for production cache clusters")
    end

    it 'synthesizes subnet group with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:tagged_subnets, {
          name: "tagged-subnet-group",
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          tags: { Name: "cache-subnets", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      subnet_group = result[:resource][:aws_elasticache_subnet_group][:tagged_subnets]

      expect(subnet_group).to have_key(:tags)
      expect(subnet_group[:tags][:Name]).to eq("cache-subnets")
      expect(subnet_group[:tags][:Environment]).to eq("production")
    end

    it 'synthesizes multiple subnet groups for different environments' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_subnet_group(:dev_subnets, {
          name: "dev-cache-subnets",
          subnet_ids: ["subnet-dev12345"],
          tags: { Environment: "development" }
        })

        aws_elasticache_subnet_group(:staging_subnets, {
          name: "staging-cache-subnets",
          subnet_ids: ["subnet-stg12345", "subnet-stg67890"],
          tags: { Environment: "staging" }
        })

        aws_elasticache_subnet_group(:prod_subnets, {
          name: "prod-cache-subnets",
          subnet_ids: ["subnet-prd12345", "subnet-prd67890", "subnet-prd11111"],
          tags: { Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      subnet_groups = result[:resource][:aws_elasticache_subnet_group]

      expect(subnet_groups).to have_key(:dev_subnets)
      expect(subnet_groups).to have_key(:staging_subnets)
      expect(subnet_groups).to have_key(:prod_subnets)
      expect(subnet_groups[:prod_subnets][:subnet_ids].length).to eq(3)
    end

    it 'synthesizes subnet group with long subnet IDs' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:long_id_subnets, {
          name: "long-id-subnets",
          subnet_ids: ["subnet-0123456789abcdef0", "subnet-fedcba9876543210f"]
        })
      end

      result = synthesizer.synthesis
      subnet_group = result[:resource][:aws_elasticache_subnet_group][:long_id_subnets]

      expect(subnet_group[:subnet_ids]).to include("subnet-0123456789abcdef0")
      expect(subnet_group[:subnet_ids]).to include("subnet-fedcba9876543210f")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:test, {
          name: "test-subnet-group",
          subnet_ids: ["subnet-12345678"]
        })
      end

      expect(ref.id).to eq("${aws_elasticache_subnet_group.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_elasticache_subnet_group.test.name}")
      expect(ref.outputs[:arn]).to eq("${aws_elasticache_subnet_group.test.arn}")
      expect(ref.outputs[:subnet_ids]).to eq("${aws_elasticache_subnet_group.test.subnet_ids}")
      expect(ref.outputs[:vpc_id]).to eq("${aws_elasticache_subnet_group.test.vpc_id}")
    end

    it 'provides computed properties for single subnet' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:single_az_test, {
          name: "single-az-test",
          subnet_ids: ["subnet-12345678"]
        })
      end

      expect(ref.computed_properties[:subnet_count]).to eq(1)
      expect(ref.computed_properties[:supports_multi_az]).to eq(false)
      expect(ref.computed_properties[:is_single_az]).to eq(true)
    end

    it 'provides computed properties for multi-az configuration' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:multi_az_test, {
          name: "multi-az-test",
          subnet_ids: ["subnet-12345678", "subnet-87654321"]
        })
      end

      expect(ref.computed_properties[:subnet_count]).to eq(2)
      expect(ref.computed_properties[:supports_multi_az]).to eq(true)
      expect(ref.computed_properties[:is_single_az]).to eq(false)
    end
  end

  describe 'resource composition' do
    it 'creates subnet group for use with cluster' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        subnet_group_ref = aws_elasticache_subnet_group(:cluster_subnets, {
          name: "cluster-subnet-group",
          subnet_ids: ["subnet-12345678", "subnet-87654321"]
        })

        aws_elasticache_cluster(:redis_in_subnets, {
          cluster_id: "redis-in-subnets",
          engine: "redis",
          node_type: "cache.t4g.micro",
          num_cache_nodes: 1,
          subnet_group_name: "cluster-subnet-group"
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource]).to have_key(:aws_elasticache_subnet_group)
      expect(result[:resource]).to have_key(:aws_elasticache_cluster)
      expect(result[:resource][:aws_elasticache_cluster][:redis_in_subnets][:subnet_group_name]).to eq("cluster-subnet-group")
    end

    it 'creates complete cache infrastructure with subnet group, parameter group, and cluster' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_subnet_group(:complete_subnets, {
          name: "complete-cache-subnets",
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          tags: { Name: "cache-subnets" }
        })

        aws_elasticache_parameter_group(:complete_params, {
          name: "complete-cache-params",
          family: "redis7.x",
          parameters: [
            { name: "maxmemory-policy", value: "allkeys-lru" }
          ],
          tags: { Name: "cache-params" }
        })

        aws_elasticache_cluster(:complete_cluster, {
          cluster_id: "complete-cache-cluster",
          engine: "redis",
          node_type: "cache.t4g.small",
          num_cache_nodes: 1,
          subnet_group_name: "complete-cache-subnets",
          parameter_group_name: "complete-cache-params",
          at_rest_encryption_enabled: true,
          transit_encryption_enabled: true,
          tags: { Name: "cache-cluster" }
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource]).to have_key(:aws_elasticache_subnet_group)
      expect(result[:resource]).to have_key(:aws_elasticache_parameter_group)
      expect(result[:resource]).to have_key(:aws_elasticache_cluster)

      cluster = result[:resource][:aws_elasticache_cluster][:complete_cluster]
      expect(cluster[:subnet_group_name]).to eq("complete-cache-subnets")
      expect(cluster[:parameter_group_name]).to eq("complete-cache-params")
    end

    it 'creates separate subnet groups for Redis and Memcached' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_elasticache_subnet_group(:redis_subnets, {
          name: "redis-cache-subnets",
          subnet_ids: ["subnet-12345678", "subnet-87654321"],
          description: "Subnets for Redis clusters"
        })

        aws_elasticache_subnet_group(:memcached_subnets, {
          name: "memcached-cache-subnets",
          subnet_ids: ["subnet-abcdef12", "subnet-12abcdef"],
          description: "Subnets for Memcached clusters"
        })
      end

      result = synthesizer.synthesis
      subnet_groups = result[:resource][:aws_elasticache_subnet_group]

      expect(subnet_groups).to have_key(:redis_subnets)
      expect(subnet_groups).to have_key(:memcached_subnets)
      expect(subnet_groups[:redis_subnets][:description]).to eq("Subnets for Redis clusters")
      expect(subnet_groups[:memcached_subnets][:description]).to eq("Subnets for Memcached clusters")
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_elasticache_subnet_group(:validation_test, {
          name: "validation-test",
          subnet_ids: ["subnet-12345678"]
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_elasticache_subnet_group]).to be_a(Hash)
      expect(result[:resource][:aws_elasticache_subnet_group][:validation_test]).to be_a(Hash)

      subnet_group_config = result[:resource][:aws_elasticache_subnet_group][:validation_test]
      expect(subnet_group_config).to have_key(:name)
      expect(subnet_group_config).to have_key(:subnet_ids)
      expect(subnet_group_config[:name]).to be_a(String)
      expect(subnet_group_config[:subnet_ids]).to be_an(Array)
    end
  end
end
