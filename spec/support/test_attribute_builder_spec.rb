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
require_relative 'test_attribute_builder'

RSpec.describe Pangea::Testing::TestAttributeBuilder do
  describe '#build' do
    it 'returns default attributes for aws_vpc' do
      result = attrs(:aws_vpc).build

      expect(result[:cidr_block]).to eq("10.0.0.0/16")
      expect(result[:enable_dns_support]).to be true
    end

    it 'returns default attributes for cloudflare_zone' do
      result = attrs(:cloudflare_zone).build

      expect(result[:zone]).to eq("example.com")
      expect(result[:plan]).to eq("free")
    end

    it 'returns empty hash for unknown resource types' do
      result = attrs(:unknown_type).build

      expect(result).to be_a(Hash)
    end
  end

  describe '#with' do
    it 'merges custom attributes' do
      result = attrs(:aws_vpc)
        .with(cidr_block: "192.168.0.0/16", custom_attr: "value")
        .build

      expect(result[:cidr_block]).to eq("192.168.0.0/16")
      expect(result[:custom_attr]).to eq("value")
    end

    it 'supports chaining' do
      builder = attrs(:aws_vpc)
      expect(builder.with(foo: "bar")).to eq(builder)
    end
  end

  describe '#tagged' do
    it 'adds tags to the attributes' do
      result = attrs(:aws_vpc)
        .tagged(Environment: "test", Project: "demo")
        .build

      expect(result[:tags][:Environment]).to eq("test")
      expect(result[:tags][:Project]).to eq("demo")
    end

    it 'supports chaining' do
      builder = attrs(:aws_vpc)
      expect(builder.tagged(Env: "test")).to eq(builder)
    end
  end

  describe '#in_vpc' do
    it 'sets vpc_id as terraform reference' do
      result = attrs(:aws_subnet).in_vpc(:main).build

      expect(result[:vpc_id]).to eq("${aws_vpc.main.id}")
    end
  end

  describe '#in_subnet' do
    it 'sets subnet_id as terraform reference' do
      result = attrs(:aws_instance).in_subnet(:private).build

      expect(result[:subnet_id]).to eq("${aws_subnet.private.id}")
    end
  end

  describe '#with_security_groups' do
    it 'sets security_group_ids as terraform references' do
      result = attrs(:aws_instance)
        .with_security_groups(:web, :ssh)
        .build

      expect(result[:security_group_ids]).to eq([
        "${aws_security_group.web.id}",
        "${aws_security_group.ssh.id}"
      ])
    end
  end

  describe '#in_zone' do
    it 'sets zone_id as terraform reference for resource name' do
      result = attrs(:cloudflare_record).in_zone(:example).build

      expect(result[:zone_id]).to eq("${cloudflare_zone.example.id}")
    end

    it 'uses literal zone_id for 32-char hex string' do
      zone_id = "023e105f4ecef8ad9ca31a8372d0c353"
      result = attrs(:cloudflare_record).in_zone(zone_id).build

      expect(result[:zone_id]).to eq(zone_id)
    end
  end

  describe '#for_domain' do
    it 'sets zone domain' do
      result = attrs(:cloudflare_zone).for_domain("custom.com").build

      expect(result[:zone]).to eq("custom.com")
    end
  end

  describe '#minimal' do
    it 'returns minimal valid attributes for aws_vpc' do
      result = attrs(:aws_vpc).minimal

      expect(result).to eq({ cidr_block: "10.0.0.0/16" })
    end

    it 'returns minimal valid attributes for cloudflare_zone' do
      result = attrs(:cloudflare_zone).minimal

      expect(result).to eq({ zone: "example.com" })
    end
  end

  describe 'full fluent chain' do
    it 'supports complex attribute building' do
      result = attrs(:aws_instance)
        .with(instance_type: "t3.medium", key_name: "my-key")
        .in_vpc(:production)
        .in_subnet(:private)
        .with_security_groups(:web, :internal)
        .tagged(Environment: "prod", Team: "platform")
        .build

      expect(result[:instance_type]).to eq("t3.medium")
      expect(result[:vpc_id]).to eq("${aws_vpc.production.id}")
      expect(result[:subnet_id]).to eq("${aws_subnet.private.id}")
      expect(result[:security_group_ids].length).to eq(2)
      expect(result[:tags][:Environment]).to eq("prod")
    end
  end
end
