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

RSpec.describe Pangea::Compilation::TemplateExtractor do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include Pangea::Compilation::TemplateExtractor

      attr_accessor :template_name, :logger

      def initialize(template_name: nil)
        @template_name = template_name
        @logger = nil
      end
    end
  end

  let(:extractor) { test_class.new }

  describe '#extract_templates' do
    context 'with a single template' do
      let(:content) do
        <<~RUBY
          template :my_vpc do
            aws_vpc :main, cidr_block: "10.0.0.0/16"
          end
        RUBY
      end

      it 'extracts the template by name' do
        templates = extractor.extract_templates(content)
        expect(templates).to have_key(:my_vpc)
      end

      it 'extracts the template content' do
        templates = extractor.extract_templates(content)
        expect(templates[:my_vpc]).to include('aws_vpc :main')
      end
    end

    context 'with multiple templates' do
      let(:content) do
        <<~RUBY
          template :vpc do
            aws_vpc :main, cidr_block: "10.0.0.0/16"
          end

          template :subnet do
            aws_subnet :private, cidr_block: "10.0.1.0/24"
          end

          template :security do
            aws_security_group :web, name: "web-sg"
          end
        RUBY
      end

      it 'extracts all templates' do
        templates = extractor.extract_templates(content)
        expect(templates.keys).to contain_exactly(:vpc, :subnet, :security)
      end

      it 'extracts correct content for each template' do
        templates = extractor.extract_templates(content)
        expect(templates[:vpc]).to include('aws_vpc')
        expect(templates[:subnet]).to include('aws_subnet')
        expect(templates[:security]).to include('aws_security_group')
      end
    end

    context 'with indented content' do
      let(:content) do
        <<~RUBY
          template :indented do
            aws_vpc :main do
              cidr_block "10.0.0.0/16"
              enable_dns_support true
            end
          end
        RUBY
      end

      it 'removes extra indentation from content' do
        templates = extractor.extract_templates(content)
        content = templates[:indented]

        # First line should not have leading spaces
        first_line = content.lines.first
        expect(first_line).to start_with('aws_vpc')
      end
    end

    context 'with no templates' do
      let(:content) do
        <<~RUBY
          # Just some Ruby code
          class MyClass
            def method
              puts "hello"
            end
          end
        RUBY
      end

      it 'returns empty hash' do
        templates = extractor.extract_templates(content)
        expect(templates).to eq({})
      end
    end

    context 'with nested blocks' do
      let(:content) do
        <<~RUBY
          template :nested do
            aws_vpc :main do
              tags do
                Name "my-vpc"
                Environment "test"
              end
            end

            aws_subnet :private do
              vpc_id ref(:main)
            end
          end
        RUBY
      end

      it 'extracts the full nested content' do
        templates = extractor.extract_templates(content)
        expect(templates[:nested]).to include('tags do')
        expect(templates[:nested]).to include('aws_subnet :private')
      end
    end

    context 'with empty template' do
      let(:content) do
        # Template with only a comment - realistic empty template
        <<~RUBY
          template :empty do
            # Empty template
          end
        RUBY
      end

      it 'extracts empty template' do
        templates = extractor.extract_templates(content)
        expect(templates).to have_key(:empty)
        expect(templates[:empty].strip).to eq('# Empty template')
      end
    end
  end

  describe '#filter_templates' do
    let(:content) do
      <<~RUBY
        template :first do
          resource "first"
        end

        template :second do
          resource "second"
        end
      RUBY
    end

    context 'when template_name is set' do
      let(:extractor) { test_class.new(template_name: 'first') }

      it 'returns only the matching template' do
        templates = extractor.extract_templates(content)
        filtered = extractor.filter_templates(templates, 'file.rb')

        expect(filtered.keys).to eq([:first])
      end
    end

    context 'when template_name does not match' do
      let(:extractor) { test_class.new(template_name: 'nonexistent') }

      it 'returns empty hash' do
        templates = extractor.extract_templates(content)
        filtered = extractor.filter_templates(templates, 'file.rb')

        expect(filtered).to eq({})
      end
    end
  end

  describe 'private methods' do
    describe '#clean_template_content' do
      it 'removes minimum indentation from all lines' do
        content = "    line1\n      line2\n    line3"
        result = extractor.send(:clean_template_content, content)

        expect(result).to eq("line1\n  line2\nline3")
      end

      it 'handles empty content' do
        result = extractor.send(:clean_template_content, '')
        expect(result).to eq('')
      end

      it 'preserves empty lines' do
        content = "    line1\n\n    line3"
        result = extractor.send(:clean_template_content, content)

        expect(result).to eq("line1\n\nline3")
      end
    end

    describe '#calculate_min_indent' do
      it 'calculates minimum indentation ignoring empty lines' do
        lines = ['    line1', '', '      line2', '    line3']
        result = extractor.send(:calculate_min_indent, lines)

        expect(result).to eq(4)
      end

      it 'returns 0 for no indentation' do
        lines = ['line1', 'line2']
        result = extractor.send(:calculate_min_indent, lines)

        expect(result).to eq(0)
      end
    end

    describe '#strip_indent' do
      it 'removes specified indentation' do
        result = extractor.send(:strip_indent, '    hello', 4)
        expect(result).to eq('hello')
      end

      it 'handles empty lines' do
        result = extractor.send(:strip_indent, '   ', 4)
        expect(result).to eq('')
      end
    end
  end
end
