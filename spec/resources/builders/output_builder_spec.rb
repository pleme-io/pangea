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
require 'pangea/resources/builders/output_builder'

RSpec.describe Pangea::Resources::Builders::OutputBuilder do
  describe '#build' do
    it 'generates basic id output for any resource' do
      builder = described_class.new(:unknown_resource, :test)
      result = builder.build

      expect(result[:id]).to eq('${unknown_resource.test.id}')
    end

    it 'includes common AWS outputs for AWS resources' do
      builder = described_class.new(:aws_vpc, :main)
      result = builder.build

      expect(result[:id]).to eq('${aws_vpc.main.id}')
      expect(result[:arn]).to eq('${aws_vpc.main.arn}')
    end

    it 'includes common Cloudflare outputs' do
      builder = described_class.new(:cloudflare_zone, :example)
      result = builder.build

      expect(result[:id]).to eq('${cloudflare_zone.example.id}')
    end

    it 'accepts custom outputs' do
      builder = described_class.new(:aws_instance, :web, :public_ip, :private_ip)
      result = builder.build

      expect(result[:id]).to eq('${aws_instance.web.id}')
      expect(result[:public_ip]).to eq('${aws_instance.web.public_ip}')
      expect(result[:private_ip]).to eq('${aws_instance.web.private_ip}')
    end

    it 'accepts array of custom outputs' do
      builder = described_class.new(:aws_instance, :web, [:public_ip, :private_ip])
      result = builder.build

      expect(result[:public_ip]).to eq('${aws_instance.web.public_ip}')
      expect(result[:private_ip]).to eq('${aws_instance.web.private_ip}')
    end
  end

  describe '#with_preset' do
    it 'uses resource-specific preset outputs for aws_vpc' do
      builder = described_class.new(:aws_vpc, :main).with_preset
      result = builder.build

      expect(result[:id]).to eq('${aws_vpc.main.id}')
      expect(result[:cidr_block]).to eq('${aws_vpc.main.cidr_block}')
      expect(result[:default_security_group_id]).to eq('${aws_vpc.main.default_security_group_id}')
    end

    it 'uses resource-specific preset outputs for cloudflare_zone' do
      builder = described_class.new(:cloudflare_zone, :example).with_preset
      result = builder.build

      expect(result[:id]).to eq('${cloudflare_zone.example.id}')
      expect(result[:status]).to eq('${cloudflare_zone.example.status}')
      expect(result[:name_servers]).to eq('${cloudflare_zone.example.name_servers}')
    end

    it 'uses resource-specific preset outputs for aws_s3_bucket' do
      builder = described_class.new(:aws_s3_bucket, :mybucket).with_preset
      result = builder.build

      expect(result[:id]).to eq('${aws_s3_bucket.mybucket.id}')
      expect(result[:arn]).to eq('${aws_s3_bucket.mybucket.arn}')
      expect(result[:bucket_domain_name]).to eq('${aws_s3_bucket.mybucket.bucket_domain_name}')
    end

    it 'allows specifying a different preset name' do
      builder = described_class.new(:my_custom_type, :instance).with_preset(:aws_instance)
      result = builder.build

      expect(result[:public_ip]).to eq('${my_custom_type.instance.public_ip}')
      expect(result[:private_dns]).to eq('${my_custom_type.instance.private_dns}')
    end
  end

  describe '#interpolation_string' do
    it 'generates correct interpolation string' do
      builder = described_class.new(:aws_vpc, :main)

      expect(builder.interpolation_string(:cidr_block)).to eq('${aws_vpc.main.cidr_block}')
    end
  end

  describe '#id' do
    it 'returns the id interpolation string' do
      builder = described_class.new(:aws_vpc, :main)

      expect(builder.id).to eq('${aws_vpc.main.id}')
    end
  end

  describe '#arn' do
    it 'returns the arn interpolation string' do
      builder = described_class.new(:aws_s3_bucket, :mybucket)

      expect(builder.arn).to eq('${aws_s3_bucket.mybucket.arn}')
    end
  end

  describe 'provider detection' do
    it 'detects AWS provider' do
      builder = described_class.new(:aws_lambda_function, :handler)
      result = builder.build

      expect(result).to have_key(:arn)
    end

    it 'detects Cloudflare provider' do
      builder = described_class.new(:cloudflare_record, :dns)
      result = builder.build

      expect(result).to have_key(:id)
    end

    it 'detects Hetzner provider' do
      builder = described_class.new(:hcloud_server, :web)
      result = builder.build

      expect(result).to have_key(:id)
    end
  end
end
