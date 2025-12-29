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

# Skip these tests if AWS SDK can't be loaded (e.g., Nix environment incompatibility)
begin
  require 'pangea/backends/s3'
  # Try to use AWS classes to detect runtime incompatibility
  Aws::S3::Client
  Aws::DynamoDB::Client
  AWS_SDK_AVAILABLE = true
rescue LoadError, NameError => e
  AWS_SDK_AVAILABLE = false
  puts "Skipping S3 backend tests: #{e.message}"
end

if AWS_SDK_AVAILABLE
  RSpec.describe Pangea::Backends::S3 do
    let(:valid_config) do
      {
        bucket: 'my-terraform-state',
        key: 'state/terraform.tfstate',
        region: 'us-east-1'
      }
    end

    let(:mock_s3_client) { instance_double(Aws::S3::Client) }
    let(:mock_dynamodb_client) { instance_double(Aws::DynamoDB::Client) }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
      allow(Aws::DynamoDB::Client).to receive(:new).and_return(mock_dynamodb_client)
    end

    describe '#initialize' do
      it 'stores the configuration' do
        backend = described_class.new(valid_config)
        expect(backend.config[:bucket]).to eq('my-terraform-state')
        expect(backend.config[:key]).to eq('state/terraform.tfstate')
        expect(backend.config[:region]).to eq('us-east-1')
      end

      it 'creates S3 client with correct region' do
        expect(Aws::S3::Client).to receive(:new).with(region: 'us-east-1')
        described_class.new(valid_config)
      end

      it 'creates DynamoDB client when dynamodb_table is provided' do
        config_with_dynamo = valid_config.merge(dynamodb_table: 'terraform-locks')
        expect(Aws::DynamoDB::Client).to receive(:new).with(region: 'us-east-1')
        described_class.new(config_with_dynamo)
      end

      it 'does not create DynamoDB client when dynamodb_table is not provided' do
        expect(Aws::DynamoDB::Client).not_to receive(:new)
        described_class.new(valid_config)
      end
    end

    describe '#type' do
      it 'returns s3' do
        backend = described_class.new(valid_config)
        expect(backend.type).to eq('s3')
      end
    end

    describe 'config validation' do
      it 'raises error when bucket is missing' do
        expect {
          described_class.new(key: 'test', region: 'us-east-1')
        }.to raise_error(ArgumentError, /Missing required S3 backend config: bucket/)
      end

      it 'raises error when key is missing' do
        expect {
          described_class.new(bucket: 'test', region: 'us-east-1')
        }.to raise_error(ArgumentError, /Missing required S3 backend config: key/)
      end

      it 'raises error when region is missing' do
        expect {
          described_class.new(bucket: 'test', key: 'test')
        }.to raise_error(ArgumentError, /Missing required S3 backend config: region/)
      end

      it 'raises error for invalid bucket name' do
        expect {
          described_class.new(bucket: 'INVALID_BUCKET', key: 'test', region: 'us-east-1')
        }.to raise_error(ArgumentError, /Invalid S3 bucket name/)
      end

      it 'raises error for invalid region format' do
        expect {
          described_class.new(bucket: 'my-bucket', key: 'test', region: 'invalid')
        }.to raise_error(ArgumentError, /Invalid AWS region/)
      end

      it 'accepts valid configuration' do
        expect {
          described_class.new(valid_config)
        }.not_to raise_error
      end

      it 'accepts bucket names with dots and hyphens' do
        expect {
          described_class.new(bucket: 'my.bucket-name.test', key: 'test', region: 'us-east-1')
        }.not_to raise_error
      end
    end

    describe '#to_terraform_config' do
      it 'returns basic S3 backend configuration' do
        backend = described_class.new(valid_config)

        expect(backend.to_terraform_config).to eq({
          s3: {
            bucket: 'my-terraform-state',
            key: 'state/terraform.tfstate',
            region: 'us-east-1'
          }
        })
      end

      it 'includes optional parameters when provided' do
        full_config = valid_config.merge(
          encrypt: true,
          dynamodb_table: 'terraform-locks',
          kms_key_id: 'arn:aws:kms:us-east-1:123456789012:key/12345678',
          workspace_key_prefix: 'env'
        )
        backend = described_class.new(full_config)

        config = backend.to_terraform_config
        expect(config[:s3][:encrypt]).to be true
        expect(config[:s3][:dynamodb_table]).to eq('terraform-locks')
        expect(config[:s3][:kms_key_id]).to eq('arn:aws:kms:us-east-1:123456789012:key/12345678')
        expect(config[:s3][:workspace_key_prefix]).to eq('env')
      end
    end

    describe '#configured?' do
      let(:backend) { described_class.new(valid_config) }

      it 'returns true when bucket exists' do
        allow(mock_s3_client).to receive(:head_bucket).and_return(true)
        expect(backend.configured?).to be true
      end

      it 'returns false when bucket does not exist' do
        allow(mock_s3_client).to receive(:head_bucket)
          .and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not found'))
        expect(backend.configured?).to be false
      end
    end

    describe '#initialize!' do
      let(:backend) { described_class.new(valid_config) }

      context 'when bucket exists' do
        before do
          allow(mock_s3_client).to receive(:head_bucket).and_return(true)
        end

        it 'returns true without creating bucket' do
          expect(mock_s3_client).not_to receive(:create_bucket)
          expect(backend.initialize!).to be true
        end
      end

      context 'when bucket does not exist' do
        before do
          allow(mock_s3_client).to receive(:head_bucket)
            .and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not found'))
          allow(mock_s3_client).to receive(:create_bucket)
          allow(mock_s3_client).to receive(:put_bucket_versioning)
        end

        it 'creates the bucket' do
          expect(mock_s3_client).to receive(:create_bucket).with(
            bucket: 'my-terraform-state',
            create_bucket_configuration: { location_constraint: 'us-east-1' }
          )
          backend.initialize!
        end

        it 'enables versioning' do
          expect(mock_s3_client).to receive(:put_bucket_versioning).with(
            bucket: 'my-terraform-state',
            versioning_configuration: { status: 'Enabled' }
          )
          backend.initialize!
        end
      end

      context 'with encryption enabled' do
        let(:encrypted_config) { valid_config.merge(encrypt: true) }
        let(:backend) { described_class.new(encrypted_config) }

        before do
          allow(mock_s3_client).to receive(:head_bucket)
            .and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not found'))
          allow(mock_s3_client).to receive(:create_bucket)
          allow(mock_s3_client).to receive(:put_bucket_versioning)
          allow(mock_s3_client).to receive(:put_bucket_encryption)
        end

        it 'enables encryption on the bucket' do
          expect(mock_s3_client).to receive(:put_bucket_encryption)
          backend.initialize!
        end
      end
    end

    describe 'locking with DynamoDB' do
      let(:config_with_dynamo) { valid_config.merge(dynamodb_table: 'terraform-locks') }
      let(:backend) { described_class.new(config_with_dynamo) }
      let(:lock_id) { 'my-state/terraform.tfstate' }

      describe '#lock' do
        it 'creates a lock item in DynamoDB' do
          expect(mock_dynamodb_client).to receive(:put_item).with(
            hash_including(
              table_name: 'terraform-locks',
              condition_expression: 'attribute_not_exists(LockID)'
            )
          )
          backend.lock(lock_id: lock_id, info: { operation: 'apply' })
        end

        it 'returns true on successful lock' do
          allow(mock_dynamodb_client).to receive(:put_item)
          expect(backend.lock(lock_id: lock_id)).to be true
        end

        it 'returns false when already locked' do
          allow(mock_dynamodb_client).to receive(:put_item)
            .and_raise(Aws::DynamoDB::Errors::ConditionalCheckFailedException.new(nil, 'Condition'))
          expect(backend.lock(lock_id: lock_id)).to be false
        end
      end

      describe '#unlock' do
        it 'deletes the lock item from DynamoDB' do
          expect(mock_dynamodb_client).to receive(:delete_item).with(
            table_name: 'terraform-locks',
            key: { LockID: lock_id }
          )
          backend.unlock(lock_id: lock_id)
        end

        it 'returns true on successful unlock' do
          allow(mock_dynamodb_client).to receive(:delete_item)
          expect(backend.unlock(lock_id: lock_id)).to be true
        end
      end

      describe '#locked?' do
        it 'returns true when lock exists' do
          allow(mock_dynamodb_client).to receive(:scan).and_return(
            double(items: [{ 'LockID' => lock_id }])
          )
          expect(backend.locked?).to be true
        end

        it 'returns false when no locks exist' do
          allow(mock_dynamodb_client).to receive(:scan).and_return(
            double(items: [])
          )
          expect(backend.locked?).to be false
        end
      end

      describe '#lock_info' do
        it 'returns lock information when locked' do
          lock_data = {
            'LockID' => lock_id,
            'Info' => '{"operation":"apply"}',
            'Created' => Time.now.to_i.to_s
          }
          allow(mock_dynamodb_client).to receive(:scan).and_return(
            double(items: [lock_data])
          )

          info = backend.lock_info
          expect(info[:id]).to eq(lock_id)
          expect(info[:info]).to eq({ 'operation' => 'apply' })
        end

        it 'returns nil when not locked' do
          allow(mock_dynamodb_client).to receive(:scan).and_return(
            double(items: [])
          )
          expect(backend.lock_info).to be_nil
        end
      end
    end

    describe 'locking without DynamoDB' do
      let(:backend) { described_class.new(valid_config) }

      it '#lock returns true without DynamoDB' do
        expect(backend.lock(lock_id: 'test')).to be true
      end

      it '#unlock returns true without DynamoDB' do
        expect(backend.unlock(lock_id: 'test')).to be true
      end

      it '#locked? returns false without DynamoDB' do
        expect(backend.locked?).to be false
      end

      it '#lock_info returns nil without DynamoDB' do
        expect(backend.lock_info).to be_nil
      end
    end
  end
else
  RSpec.describe 'Pangea::Backends::S3' do
    it 'is skipped because AWS SDK is not available' do
      skip 'AWS SDK not available in this environment'
    end
  end
end
