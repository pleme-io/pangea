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
require 'pangea/compilation/template_compiler'
require 'pangea/resources/cloudflare_zone/resource'
require 'pangea/resources/cloudflare_zone/types'
require 'tmpdir'

RSpec.describe Pangea::Compilation::TemplateCompiler do
  let(:tmp_dir) { Dir.mktmpdir('pangea_compiler_test') }

  after(:each) do
    FileUtils.rm_rf(tmp_dir) if File.exist?(tmp_dir)
  end

  describe '#initialize' do
    it 'creates a TerraformSynthesizer' do
      compiler = described_class.new
      expect(compiler.synthesizer).to be_a(TerraformSynthesizer)
    end

    it 'accepts namespace parameter' do
      compiler = described_class.new(namespace: 'production')
      expect(compiler.namespace).to eq('production')
    end

    it 'accepts template_name parameter' do
      compiler = described_class.new(template_name: 'my_template')
      expect(compiler).to be_a(described_class)
    end
  end

  describe '#compile_file' do
    context 'with a simple template using cloudflare_zone' do
      let(:file_path) { File.join(tmp_dir, 'simple.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :simple do
            cloudflare_zone(:example, {
              zone: "example.com"
            })
          end
        RUBY
      end

      it 'compiles the template successfully' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
      end

      it 'produces valid Terraform JSON with cloudflare_zone resource' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        json = JSON.parse(result.terraform_json)
        expect(json['resource']).to have_key('cloudflare_zone')
        expect(json['resource']['cloudflare_zone']['example']['zone']).to eq('example.com')
      end
    end

    context 'with multiple templates' do
      let(:file_path) { File.join(tmp_dir, 'multi.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :first do
            cloudflare_zone(:first_zone, {
              zone: "first.com"
            })
          end

          template :second do
            cloudflare_zone(:second_zone, {
              zone: "second.com"
            })
          end
        RUBY
      end

      it 'compiles all templates' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
        expect(result.template_count).to eq(2)
      end
    end

    context 'with template_name filter' do
      let(:file_path) { File.join(tmp_dir, 'multi.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :first do
            cloudflare_zone(:first_zone, {
              zone: "first.com"
            })
          end

          template :second do
            cloudflare_zone(:second_zone, {
              zone: "second.com"
            })
          end
        RUBY
      end

      it 'compiles only the specified template' do
        compiler = described_class.new(template_name: 'first')
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
        expect(result.template_name).to eq('first')

        json = JSON.parse(result.terraform_json)
        expect(json['resource']['cloudflare_zone']).to have_key('first_zone')
        expect(json['resource']['cloudflare_zone']).not_to have_key('second_zone')
      end

      it 'returns error for non-existent template' do
        compiler = described_class.new(template_name: 'nonexistent')
        result = compiler.compile_file(file_path)

        expect(result.success).to be false
        expect(result.errors.first).to include('nonexistent')
      end
    end

    context 'with syntax error in template' do
      let(:file_path) { File.join(tmp_dir, 'syntax_error.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :broken do
            cloudflare_zone(:example {
              zone: "example.com"
            })
          end
        RUBY
      end

      it 'returns error result' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be false
        expect(result.errors.first).to match(/Syntax error|unexpected/)
      end
    end

    context 'with runtime error in template' do
      let(:file_path) { File.join(tmp_dir, 'runtime_error.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :broken do
            raise "Intentional error for testing"
          end
        RUBY
      end

      it 'returns error result' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be false
        expect(result.errors.first).to include('Compilation error')
      end
    end

    context 'with non-existent file' do
      it 'raises CompilationError' do
        compiler = described_class.new
        expect {
          compiler.compile_file('/nonexistent/path.rb')
        }.to raise_error(Pangea::Compilation::CompilationError, /File not found/)
      end
    end

    context 'with provider configuration' do
      let(:file_path) { File.join(tmp_dir, 'with_provider.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :with_provider do
            provider :cloudflare do
              api_token "fake-token"
            end

            cloudflare_zone(:example, {
              zone: "example.com"
            })
          end
        RUBY
      end

      it 'includes provider in output' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
        json = JSON.parse(result.terraform_json)
        expect(json['provider']).to have_key('cloudflare')
      end

      it 'does not warn about missing provider' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.warnings).not_to include('No provider configuration found')
      end
    end

    context 'with empty template' do
      let(:file_path) { File.join(tmp_dir, 'empty.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :empty do
            # Empty template - no content
          end
        RUBY
      end

      it 'compiles successfully with warnings' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
        expect(result.warnings).to include('No resources defined in template')
      end
    end

    context 'with complex cloudflare configuration' do
      let(:file_path) { File.join(tmp_dir, 'complex.rb') }

      before do
        File.write(file_path, <<~RUBY)
          template :complex do
            cloudflare_zone(:production, {
              zone: "example.com",
              account_id: "#{'f' * 32}",
              plan: "pro",
              jump_start: true
            })
          end
        RUBY
      end

      it 'compiles with all attributes' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
        json = JSON.parse(result.terraform_json)
        zone = json['resource']['cloudflare_zone']['production']
        expect(zone['zone']).to eq('example.com')
        expect(zone['plan']).to eq('pro')
        expect(zone['jump_start']).to be true
      end
    end
  end

  describe 'parallel compilation' do
    let(:file_path) { File.join(tmp_dir, 'many_templates.rb') }

    before do
      templates = (1..5).map do |i|
        <<~RUBY
          template :template_#{i} do
            cloudflare_zone(:zone_#{i}, {
              zone: "site#{i}.com"
            })
          end
        RUBY
      end.join("\n")

      File.write(file_path, templates)
    end

    it 'compiles multiple templates' do
      compiler = described_class.new
      result = compiler.compile_file(file_path)

      expect(result.success).to be true
      expect(result.template_count).to eq(5)
    end

    context 'with PANGEA_NO_PARALLEL set' do
      around do |example|
        old_val = ENV['PANGEA_NO_PARALLEL']
        ENV['PANGEA_NO_PARALLEL'] = '1'
        example.run
        ENV['PANGEA_NO_PARALLEL'] = old_val
      end

      it 'still compiles all templates' do
        compiler = described_class.new
        result = compiler.compile_file(file_path)

        expect(result.success).to be true
        expect(result.template_count).to eq(5)
      end
    end
  end
end

RSpec.describe Pangea::Compilation::CompilationError do
  it 'is a StandardError' do
    expect(described_class.superclass).to eq(StandardError)
  end

  it 'can be raised with a message' do
    expect {
      raise described_class, 'test error'
    }.to raise_error(described_class, 'test error')
  end
end
