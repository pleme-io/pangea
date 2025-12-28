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
require 'pangea/resources/aws_kinesis_firehose_delivery_stream/resource'

RSpec.describe 'aws_kinesis_firehose_delivery_stream synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:role_arn) { 'arn:aws:iam::123456789012:role/firehose-role' }
  let(:bucket_arn) { 'arn:aws:s3:::my-bucket' }
  let(:kinesis_stream_arn) { 'arn:aws:kinesis:us-east-1:123456789012:stream/my-stream' }

  describe 'terraform synthesis' do
    it 'synthesizes basic S3 delivery stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:logs, {
          name: 'logs-delivery',
          destination: 's3',
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:logs]

      expect(stream[:name]).to eq('logs-delivery')
      expect(stream[:destination]).to eq('s3')
    end

    it 'synthesizes extended S3 delivery stream with prefix' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:events, {
          name: 'events-delivery',
          destination: 'extended_s3',
          extended_s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket',
            prefix: 'events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/',
            error_output_prefix: 'errors/',
            buffer_size: 64,
            buffer_interval: 300,
            compression_format: 'GZIP'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:events]

      expect(stream[:destination]).to eq('extended_s3')
      expect(stream[:extended_s3_configuration][:compression_format]).to eq('GZIP')
      expect(stream[:extended_s3_configuration][:buffer_size]).to eq(64)
    end

    it 'synthesizes delivery stream with Kinesis source' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:from_kinesis, {
          name: 'kinesis-to-s3',
          destination: 's3',
          kinesis_source_configuration: {
            kinesis_stream_arn: 'arn:aws:kinesis:us-east-1:123456789012:stream/my-stream',
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role'
          },
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:from_kinesis]

      expect(stream[:kinesis_source_configuration][:kinesis_stream_arn]).to include('kinesis')
    end

    it 'synthesizes delivery stream with server-side encryption' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:encrypted, {
          name: 'encrypted-delivery',
          destination: 's3',
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          },
          server_side_encryption: {
            enabled: true,
            key_type: 'AWS_OWNED_CMK'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:encrypted]

      expect(stream[:server_side_encryption][:enabled]).to be true
      expect(stream[:server_side_encryption][:key_type]).to eq('AWS_OWNED_CMK')
    end

    it 'synthesizes Elasticsearch delivery stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:to_es, {
          name: 'to-elasticsearch',
          destination: 'elasticsearch',
          elasticsearch_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            domain_arn: 'arn:aws:es:us-east-1:123456789012:domain/my-domain',
            index_name: 'logs',
            index_rotation_period: 'OneDay',
            buffering_size: 5,
            buffering_interval: 60,
            s3_backup_mode: 'FailedDocumentsOnly'
          },
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:to_es]

      expect(stream[:destination]).to eq('elasticsearch')
      expect(stream[:elasticsearch_configuration][:index_name]).to eq('logs')
      expect(stream[:elasticsearch_configuration][:index_rotation_period]).to eq('OneDay')
    end

    it 'synthesizes HTTP endpoint delivery stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:to_http, {
          name: 'to-http-endpoint',
          destination: 'http_endpoint',
          http_endpoint_configuration: {
            url: 'https://api.example.com/ingest',
            name: 'ExampleAPI',
            buffering_size: 5,
            buffering_interval: 60,
            retry_duration: 300,
            s3_backup_mode: 'FailedDataOnly'
          },
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:to_http]

      expect(stream[:destination]).to eq('http_endpoint')
      expect(stream[:http_endpoint_configuration][:url]).to eq('https://api.example.com/ingest')
    end

    it 'synthesizes Splunk delivery stream' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:to_splunk, {
          name: 'to-splunk',
          destination: 'splunk',
          splunk_configuration: {
            hec_endpoint: 'https://splunk.example.com:8088',
            hec_token: 'my-hec-token',
            hec_endpoint_type: 'Event',
            retry_duration: 300,
            s3_backup_mode: 'FailedEventsOnly'
          },
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:to_splunk]

      expect(stream[:destination]).to eq('splunk')
      expect(stream[:splunk_configuration][:hec_endpoint_type]).to eq('Event')
    end

    it 'synthesizes stream with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:tagged, {
          name: 'tagged-delivery',
          destination: 's3',
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          },
          tags: { Environment: 'production', Team: 'data-platform' }
        })
      end

      result = synthesizer.synthesis
      stream = result[:resource][:aws_kinesis_firehose_delivery_stream][:tagged]

      expect(stream[:tags][:Environment]).to eq('production')
      expect(stream[:tags][:Team]).to eq('data-platform')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:test, {
          name: 'test-delivery',
          destination: 's3',
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_kinesis_firehose_delivery_stream.test.arn}')
      expect(ref.outputs[:name]).to eq('${aws_kinesis_firehose_delivery_stream.test.name}')
      expect(ref.outputs[:id]).to eq('${aws_kinesis_firehose_delivery_stream.test.id}')
    end
  end

  describe 'terraform validation' do
    it 'produces valid terraform structure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_kinesis_firehose_delivery_stream(:test, {
          name: 'test-delivery',
          destination: 's3',
          s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::my-bucket'
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result[:resource]).to be_a(Hash)
      expect(result[:resource][:aws_kinesis_firehose_delivery_stream]).to be_a(Hash)
      expect(result[:resource][:aws_kinesis_firehose_delivery_stream][:test]).to be_a(Hash)
    end
  end

  describe 'resource composition' do
    it 'creates complete data pipeline infrastructure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS

        # Raw data delivery
        aws_kinesis_firehose_delivery_stream(:raw_data, {
          name: 'raw-data-delivery',
          destination: 'extended_s3',
          extended_s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::raw-data-bucket',
            prefix: 'raw/',
            compression_format: 'GZIP'
          }
        })

        # Processed data delivery
        aws_kinesis_firehose_delivery_stream(:processed_data, {
          name: 'processed-data-delivery',
          destination: 'extended_s3',
          extended_s3_configuration: {
            role_arn: 'arn:aws:iam::123456789012:role/firehose-role',
            bucket_arn: 'arn:aws:s3:::processed-data-bucket',
            prefix: 'processed/',
            compression_format: 'Snappy'
          }
        })
      end

      result = synthesizer.synthesis
      streams = result[:resource][:aws_kinesis_firehose_delivery_stream]

      expect(streams).to have_key(:raw_data)
      expect(streams).to have_key(:processed_data)
      expect(streams[:raw_data][:extended_s3_configuration][:compression_format]).to eq('GZIP')
      expect(streams[:processed_data][:extended_s3_configuration][:compression_format]).to eq('Snappy')
    end
  end
end
