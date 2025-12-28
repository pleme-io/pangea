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
require 'pangea/resources/aws_kinesis_stream/resource'

RSpec.describe 'aws_kinesis_stream synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic Kinesis stream with minimal configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:events, {
          name: 'events-stream'
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:events]

      expect(stream[:name]).to eq('events-stream')
      expect(stream[:shard_count]).to eq(1)
      expect(stream[:retention_period]).to eq(24)
    end

    it 'synthesizes stream with custom shard count' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:high_throughput, {
          name: 'high-throughput-stream',
          shard_count: 4
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:high_throughput]

      expect(stream[:name]).to eq('high-throughput-stream')
      expect(stream[:shard_count]).to eq(4)
    end

    it 'synthesizes stream with extended retention period' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:long_retention, {
          name: 'long-retention-stream',
          retention_period: 168  # 7 days
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:long_retention]

      expect(stream[:retention_period]).to eq(168)
    end

    it 'synthesizes encrypted stream with KMS' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:encrypted, {
          name: 'encrypted-stream',
          encryption_type: 'KMS',
          kms_key_id: 'alias/kinesis-key'
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:encrypted]

      expect(stream[:encryption_type]).to eq('KMS')
      expect(stream[:kms_key_id]).to eq('alias/kinesis-key')
    end

    it 'synthesizes stream with shard level metrics' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:monitored, {
          name: 'monitored-stream',
          shard_level_metrics: ['IncomingRecords', 'OutgoingRecords', 'IncomingBytes']
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:monitored]

      expect(stream[:shard_level_metrics]).to include('IncomingRecords')
      expect(stream[:shard_level_metrics]).to include('OutgoingRecords')
      expect(stream[:shard_level_metrics]).to include('IncomingBytes')
    end

    it 'synthesizes on-demand stream mode' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:on_demand, {
          name: 'on-demand-stream',
          stream_mode_details: { stream_mode: 'ON_DEMAND' }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:on_demand]

      expect(stream[:stream_mode_details][:stream_mode]).to eq('ON_DEMAND')
    end

    it 'synthesizes stream with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:tagged, {
          name: 'tagged-stream',
          tags: { Environment: 'production', Team: 'data-platform' }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_stream][:tagged]

      expect(stream[:tags][:Environment]).to eq('production')
      expect(stream[:tags][:Team]).to eq('data-platform')
    end

    it 'synthesizes multiple streams for different purposes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_kinesis_stream(:user_events, {
          name: 'user-events-stream',
          shard_count: 2,
          retention_period: 48
        })

        aws_kinesis_stream(:system_logs, {
          name: 'system-logs-stream',
          shard_count: 4,
          retention_period: 168
        })
      end

      result = synthesizer.synthesis
      streams = result[:resource][:aws_kinesis_stream]

      expect(streams).to have_key(:user_events)
      expect(streams).to have_key(:system_logs)
      expect(streams[:user_events][:shard_count]).to eq(2)
      expect(streams[:system_logs][:shard_count]).to eq(4)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:test, { name: 'test-stream' })
      end

      expect(ref.outputs[:arn]).to eq('${aws_kinesis_stream.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_kinesis_stream.test.name}')
      expect(ref.outputs[:id]).to eq('${aws_kinesis_stream.test.id}')
    end

    it 'provides computed property methods' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:test, {
          name: 'test-stream',
          shard_count: 2,
          encryption_type: 'KMS',
          kms_key_id: 'alias/test-key'
        })
      end

      expect(ref.is_encrypted?).to be true
      expect(ref.is_provisioned_mode?).to be true
      expect(ref.max_throughput_per_shard_mbps).to eq(1.0)
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_stream(:test, { name: 'test-stream' })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_kinesis_stream]).to be_a(Hash)
      expect(result[:resource][:aws_kinesis_stream][:test]).to be_a(Hash)
    end
  end
end
