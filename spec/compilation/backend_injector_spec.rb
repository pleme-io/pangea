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

# Load the backend injector module
require 'pangea/compilation/template_compiler'

RSpec.describe Pangea::Compilation::BackendInjector do
  # Create a test class that includes the module
  let(:test_class) do
    klass = Class.new do
      include Pangea::Compilation::BackendInjector

      attr_accessor :synthesizer, :namespace, :logger

      def initialize(namespace: nil)
        @synthesizer = TerraformSynthesizer.new
        @namespace = namespace
        @logger = nil
      end
    end
    klass
  end

  let(:mock_namespace) do
    double('NamespaceEntity',
      to_terraform_backend: {
        s3: {
          bucket: 'my-state-bucket',
          key: 'base/path',
          region: 'us-east-1'
        }
      }
    )
  end

  let(:mock_config) do
    double('Config')
  end

  before do
    allow(Pangea).to receive(:config).and_return(mock_config)
  end

  describe '#inject_backend_config' do
    context 'when namespace is nil' do
      let(:injector) { test_class.new(namespace: nil) }

      it 'returns early without modifying synthesizer' do
        expect(injector.synthesizer).not_to receive(:synthesize)
        injector.inject_backend_config('my_template')
      end
    end

    context 'when namespace entity is not found' do
      let(:injector) { test_class.new(namespace: 'unknown') }

      before do
        allow(mock_config).to receive(:namespace).with('unknown').and_return(nil)
      end

      it 'returns early without modifying synthesizer' do
        expect(injector.synthesizer).not_to receive(:synthesize)
        injector.inject_backend_config('my_template')
      end
    end

    context 'when namespace loading raises an error' do
      let(:injector) { test_class.new(namespace: 'broken') }

      before do
        allow(mock_config).to receive(:namespace)
          .with('broken')
          .and_raise(StandardError.new('Config error'))
      end

      it 'catches the error and returns early' do
        expect { injector.inject_backend_config('my_template') }.not_to raise_error
      end
    end

    context 'with valid S3 backend configuration' do
      let(:injector) { test_class.new(namespace: 'production') }

      before do
        allow(mock_config).to receive(:namespace)
          .with('production')
          .and_return(mock_namespace)
      end

      it 'injects backend config with template-specific key' do
        injector.inject_backend_config('my_template')

        synthesis = injector.synthesizer.synthesis
        expect(synthesis[:terraform]).to be_a(Hash)
        expect(synthesis[:terraform][:backend]).to be_a(Hash)
        expect(synthesis[:terraform][:backend][:s3]).to be_a(Hash)
        expect(synthesis[:terraform][:backend][:s3][:key]).to eq('base/path/my_template/terraform.tfstate')
      end

      it 'preserves other backend configuration' do
        injector.inject_backend_config('my_template')

        synthesis = injector.synthesizer.synthesis
        backend = synthesis[:terraform][:backend][:s3]
        expect(backend[:bucket]).to eq('my-state-bucket')
        expect(backend[:region]).to eq('us-east-1')
      end
    end

    context 'with local backend configuration' do
      let(:mock_local_namespace) do
        double('NamespaceEntity',
          to_terraform_backend: {
            local: {
              path: 'original.tfstate'
            }
          }
        )
      end

      let(:injector) { test_class.new(namespace: 'local_ns') }

      before do
        allow(mock_config).to receive(:namespace)
          .with('local_ns')
          .and_return(mock_local_namespace)
      end

      it 'sets template-specific path for local backend' do
        injector.inject_backend_config('my_template')

        synthesis = injector.synthesizer.synthesis
        backend = synthesis[:terraform][:backend][:local]
        expect(backend[:path]).to eq('my_template.tfstate')
      end
    end

    context 'when S3 key is nil or empty' do
      let(:mock_empty_key_namespace) do
        double('NamespaceEntity',
          to_terraform_backend: {
            s3: {
              bucket: 'my-bucket',
              key: '',
              region: 'us-east-1'
            }
          }
        )
      end

      let(:injector) { test_class.new(namespace: 'empty_key') }

      before do
        allow(mock_config).to receive(:namespace)
          .with('empty_key')
          .and_return(mock_empty_key_namespace)
      end

      it 'raises an error about empty key' do
        expect {
          injector.inject_backend_config('my_template')
        }.to raise_error(/S3 backend key is nil or empty/)
      end
    end
  end

  describe '#prepare_backend_config (private)' do
    let(:injector) { test_class.new(namespace: 'test') }

    it 'appends template name to S3 key path' do
      result = injector.send(:prepare_backend_config, mock_namespace, 'my_template')

      expect(result[:s3][:key]).to eq('base/path/my_template/terraform.tfstate')
    end
  end
end
