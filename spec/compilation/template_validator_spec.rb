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
require 'pangea/compilation/template_compiler'
require 'tmpdir'

RSpec.describe Pangea::Compilation::TemplateValidator do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include Pangea::Compilation::TemplateValidator

      attr_accessor :synthesizer, :template_name

      def initialize
        @synthesizer = TerraformSynthesizer.new
        @template_name = 'test_template'
      end
    end
  end

  let(:validator) { test_class.new }

  describe '#collect_warnings' do
    context 'with empty synthesis' do
      it 'warns about no resources defined' do
        warnings = validator.collect_warnings
        expect(warnings).to include('No resources defined in template')
      end

      it 'warns about no provider configuration' do
        warnings = validator.collect_warnings
        expect(warnings).to include('No provider configuration found')
      end
    end

    context 'with resources defined' do
      before do
        validator.synthesizer.synthesize do
          resource :aws_vpc, :main do
            cidr_block "10.0.0.0/16"
          end
        end
      end

      it 'does not warn about missing resources' do
        warnings = validator.collect_warnings
        expect(warnings).not_to include('No resources defined in template')
      end
    end

    context 'with provider configured' do
      before do
        validator.synthesizer.synthesize do
          provider :aws do
            region "us-east-1"
          end
        end
      end

      it 'does not warn about missing provider' do
        warnings = validator.collect_warnings
        expect(warnings).not_to include('No provider configuration found')
      end
    end
  end

  describe '#validate_file!' do
    let(:tmp_dir) { Dir.mktmpdir('pangea_validator_test') }

    after(:each) do
      FileUtils.rm_rf(tmp_dir) if File.exist?(tmp_dir)
    end

    context 'with existing readable file' do
      let(:file_path) { File.join(tmp_dir, 'test.rb') }

      before do
        File.write(file_path, 'content')
      end

      it 'does not raise an error' do
        expect { validator.validate_file!(file_path) }.not_to raise_error
      end
    end

    context 'with non-existent file' do
      it 'raises CompilationError' do
        expect {
          validator.validate_file!('/nonexistent/file.rb')
        }.to raise_error(Pangea::Compilation::CompilationError, /File not found/)
      end
    end

    context 'with unreadable file' do
      let(:file_path) { File.join(tmp_dir, 'unreadable.rb') }

      before do
        File.write(file_path, 'content')
        File.chmod(0o000, file_path)
      end

      after do
        File.chmod(0o644, file_path) rescue nil
      end

      it 'raises CompilationError' do
        skip 'Test requires non-root user' if Process.uid == 0
        expect {
          validator.validate_file!(file_path)
        }.to raise_error(Pangea::Compilation::CompilationError, /File not readable/)
      end
    end
  end

  describe '#template_not_found_error' do
    it 'returns a CompilationResult with success false' do
      result = validator.template_not_found_error('/path/to/file.rb')
      expect(result.success).to be false
    end

    it 'includes template name in error message' do
      result = validator.template_not_found_error('/path/to/file.rb')
      expect(result.errors.first).to include('test_template')
    end

    it 'includes file path in error message' do
      result = validator.template_not_found_error('/path/to/file.rb')
      expect(result.errors.first).to include('/path/to/file.rb')
    end
  end

  describe '#validate_resources' do
    let(:mock_logger) do
      double('Logger').tap do |logger|
        allow(logger).to receive(:debug)
        allow(logger).to receive(:warn)
      end
    end

    let(:mock_validator_manager) do
      double('ValidatorManager').tap do |v|
        allow(v).to receive(:validate_terraform_config)
        allow(v).to receive(:failures).and_return([])
        allow(v).to receive(:warnings).and_return([])
        allow(v).to receive(:summary).and_return({ total: 0, passed: 0, failed: 0 })
      end
    end

    before do
      stub_const('Pangea::Validation::ValidatorManager', Class.new do
        define_method(:initialize) {}
        define_method(:validate_terraform_config) { |_| }
        define_method(:failures) { [] }
        define_method(:warnings) { [] }
        define_method(:summary) { { total: 0, passed: 0, failed: 0 } }
      end)
    end

    it 'returns empty warnings array when no issues found' do
      terraform_json = { resource: { aws_vpc: { main: {} } } }
      warnings = validator.validate_resources(terraform_json, 'test', mock_logger)
      expect(warnings).to eq([])
    end

    context 'with validation failures' do
      before do
        stub_const('Pangea::Validation::ValidatorManager', Class.new do
          define_method(:initialize) {}
          define_method(:validate_terraform_config) { |_| }
          define_method(:failures) do
            [{
              resource_type: :aws_vpc,
              resource_name: :main,
              errors: { cidr_block: ['is required'] }
            }]
          end
          define_method(:warnings) { [] }
          define_method(:summary) { { total: 1, passed: 0, failed: 1 } }
        end)
      end

      it 'collects validation failures as warnings' do
        terraform_json = { resource: { aws_vpc: { main: {} } } }
        warnings = validator.validate_resources(terraform_json, 'test', mock_logger)

        expect(warnings).to include('aws_vpc.main: cidr_block is required')
      end
    end
  end
end
