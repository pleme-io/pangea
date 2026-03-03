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
  require 'pangea/backends'
  # Try to use AWS classes to detect runtime incompatibility
  Aws::S3::Client
  BACKENDS_AVAILABLE = true
rescue LoadError, NameError => e
  BACKENDS_AVAILABLE = false
  puts "Skipping backends tests: #{e.message}"
end

if BACKENDS_AVAILABLE
  RSpec.describe Pangea::Backends do
    let(:mock_s3_client) { instance_double(Aws::S3::Client) }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)
    end

    describe '.create' do
      context 'with s3 type' do
        let(:s3_config) do
          { bucket: 'my-bucket', key: 'state.tfstate', region: 'us-east-1' }
        end

        it 'creates an S3 backend' do
          backend = described_class.create(type: 's3', config: s3_config)
          expect(backend).to be_a(Pangea::Backends::S3)
        end

        it 'accepts symbol type' do
          backend = described_class.create(type: :s3, config: s3_config)
          expect(backend).to be_a(Pangea::Backends::S3)
        end
      end

      context 'with local type' do
        it 'creates a Local backend' do
          backend = described_class.create(type: 'local', config: { path: 'test.tfstate' })
          expect(backend).to be_a(Pangea::Backends::Local)
        end

        it 'accepts symbol type' do
          backend = described_class.create(type: :local, config: {})
          expect(backend).to be_a(Pangea::Backends::Local)
        end
      end

      context 'with unknown type' do
        it 'raises ArgumentError' do
          expect {
            described_class.create(type: 'unknown')
          }.to raise_error(ArgumentError, /Unknown backend type: unknown/)
        end

        it 'lists available backends in error message' do
          expect {
            described_class.create(type: 'gcs')
          }.to raise_error(ArgumentError, /Available: s3, local/)
        end
      end
    end

    describe '.from_namespace' do
      context 'with S3 state configuration' do
        let(:namespace) do
          double('Namespace', state: {
            type: 's3',
            bucket: 'my-bucket',
            key: 'state.tfstate',
            region: 'us-east-1'
          })
        end

        it 'creates an S3 backend from namespace' do
          backend = described_class.from_namespace(namespace)
          expect(backend).to be_a(Pangea::Backends::S3)
        end
      end

      context 'with local state configuration' do
        let(:namespace) do
          double('Namespace', state: {
            type: 'local',
            path: 'terraform.tfstate'
          })
        end

        it 'creates a Local backend from namespace' do
          backend = described_class.from_namespace(namespace)
          expect(backend).to be_a(Pangea::Backends::Local)
        end
      end

      context 'with no state configuration' do
        let(:namespace) { double('Namespace', state: nil) }

        it 'returns nil' do
          expect(described_class.from_namespace(namespace)).to be_nil
        end
      end
    end

    describe 'REGISTRY' do
      it 'contains s3 backend' do
        expect(described_class::REGISTRY['s3']).to eq(Pangea::Backends::S3)
      end

      it 'contains local backend' do
        expect(described_class::REGISTRY['local']).to eq(Pangea::Backends::Local)
      end

      it 'is frozen' do
        expect(described_class::REGISTRY).to be_frozen
      end
    end
  end
else
  RSpec.describe 'Pangea::Backends' do
    it 'is skipped because backends module is not available' do
      skip 'Backends module not available in this environment'
    end
  end
end
