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
require 'pangea/resources/aws_dynamodb_kinesis_streaming_destination/resource'

RSpec.describe 'aws_dynamodb_kinesis_streaming_destination synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:stream_arn) { 'arn:aws:kinesis:us-east-1:123456789012:stream/my-stream' }

  describe 'terraform synthesis' do
    it 'synthesizes basic DynamoDB Kinesis streaming destination' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_kinesis_streaming_destination(:orders_stream, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/orders-stream',
          table_name: 'orders'
        })
      end

      result = synthesizer.synthesis
      destination = result[:resource][:aws_dynamodb_kinesis_streaming_destination][:orders_stream]

      expect(destination[:stream_arn]).to eq('arn:aws:kinesis:us-east-1:123456789012:stream/orders-stream')
      expect(destination[:table_name]).to eq('orders')
    end

    it 'synthesizes streaming destination for multiple tables' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_dynamodb_kinesis_streaming_destination(:users_stream, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/cdc-stream',
          table_name: 'users'
        })

        aws_dynamodb_kinesis_streaming_destination(:products_stream, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/cdc-stream',
          table_name: 'products'
        })

        aws_dynamodb_kinesis_streaming_destination(:orders_stream, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/cdc-stream',
          table_name: 'orders'
        })
      end

      result = synthesizer.synthesis
      destinations = result[:resource][:aws_dynamodb_kinesis_streaming_destination]

      expect(destinations).to have_key(:users_stream)
      expect(destinations).to have_key(:products_stream)
      expect(destinations).to have_key(:orders_stream)
    end

    it 'synthesizes streaming destinations with different streams per table' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        aws_dynamodb_kinesis_streaming_destination(:critical_events, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/critical-events',
          table_name: 'critical_data'
        })

        aws_dynamodb_kinesis_streaming_destination(:analytics_events, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/analytics-events',
          table_name: 'analytics_data'
        })
      end

      result = synthesizer.synthesis
      destinations = result[:resource][:aws_dynamodb_kinesis_streaming_destination]

      expect(destinations[:critical_events][:stream_arn]).to include('critical-events')
      expect(destinations[:analytics_events][:stream_arn]).to include('analytics-events')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_kinesis_streaming_destination(:test, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/test-stream',
          table_name: 'test_table'
        })
      end

      expect(ref.outputs[:id]).to eq('${aws_dynamodb_kinesis_streaming_destination.test.id}')
      expect(ref.outputs[:stream_arn]).to eq('${aws_dynamodb_kinesis_streaming_destination.test.stream_arn}')
      expect(ref.outputs[:table_name]).to eq('${aws_dynamodb_kinesis_streaming_destination.test.table_name}')
    end

    it 'provides computed properties' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_kinesis_streaming_destination(:test, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/my-cdc-stream',
          table_name: 'test_table'
        })
      end

      expect(ref.computed[:stream_name]).to eq('my-cdc-stream')
      expect(ref.computed[:stream_region]).to eq('us-east-1')
      expect(ref.computed[:stream_account_id]).to eq('123456789012')
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_kinesis_streaming_destination(:test, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/test-stream',
          table_name: 'test_table'
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_dynamodb_kinesis_streaming_destination]).to be_a(Hash)
      expect(result[:resource][:aws_dynamodb_kinesis_streaming_destination][:test]).to be_a(Hash)
    end
  end

  describe 'resource composition' do
    it 'creates complete CDC (Change Data Capture) infrastructure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        # Create Kinesis stream for CDC events
        aws_kinesis_stream(:cdc_stream, {
          name: 'dynamodb-cdc-stream',
          shard_count: 4,
          retention_period: 168
        })

        # Create streaming destinations for multiple tables
        aws_dynamodb_kinesis_streaming_destination(:users_cdc, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/dynamodb-cdc-stream',
          table_name: 'users'
        })

        aws_dynamodb_kinesis_streaming_destination(:orders_cdc, {
          stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/dynamodb-cdc-stream',
          table_name: 'orders'
        })

        # Create Firehose delivery stream to S3 for archival
        aws_kinesis_firehose_delivery_stream(:cdc_archive, {
          name: 'cdc-archive-delivery',
          destination: 'extended_s3',
          kinesis_source_configuration: {
            kinesis_stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/dynamodb-cdc-stream',
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role'
          },
          extended_s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::cdc-archive-bucket',
            prefix: 'cdc-data/',
            compression_format: 'GZIP'
          }
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:aws_kinesis_stream]).to have_key(:cdc_stream)
      expect(result[:resource][:aws_dynamodb_kinesis_streaming_destination]).to have_key(:users_cdc)
      expect(result[:resource][:aws_dynamodb_kinesis_streaming_destination]).to have_key(:orders_cdc)
      expect(result[:resource][:aws_kinesis_firehose_delivery_stream]).to have_key(:cdc_archive)
    end
  end
end
