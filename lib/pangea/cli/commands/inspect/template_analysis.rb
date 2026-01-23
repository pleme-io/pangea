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

module Pangea
  module CLI
    module Commands
      # Template analysis methods for inspect command
      module TemplateAnalysis
          private

          def inspect_templates(file, template: nil)
            return { error: 'File required for template inspection' } unless file
            return { error: "File not found: #{file}" } unless File.exist?(file)

            compiler = Compilation::TemplateCompiler.new
            templates = compiler.extract_templates(file)

            if template
              specific_template = templates.find { |t| t[:name].to_s == template.to_s }
              return { error: "Template '#{template}' not found in #{file}" } unless specific_template

              analyze_template(specific_template, file)
            else
              { file: file, template_count: templates.size, templates: templates.map { |t| analyze_template(t, file) } }
            end
          end

          def analyze_template(template, file)
            {
              name: template[:name],
              line_number: template[:line],
              file: file,
              analysis: {
                providers: extract_providers(template[:content]),
                resources: extract_resources(template[:content]),
                data_sources: extract_data_sources(template[:content]),
                outputs: extract_outputs(template[:content]),
                locals: extract_locals(template[:content]),
                module_calls: extract_module_calls(template[:content]),
                resource_functions: extract_resource_functions(template[:content]),
                architecture_functions: extract_architecture_functions(template[:content]),
                component_functions: extract_component_functions(template[:content])
              }
            }
          end

          def extract_providers(content)
            providers = []
            content.scan(/provider\s+:(\w+)/) { |match| providers << { type: match[0] } }
            providers
          end

          def extract_resources(content)
            resources = []
            content.scan(/resource\s+:(\w+),\s*:(\w+)/) { |type, name| resources << { type: type, name: name } }
            resources
          end

          def extract_data_sources(content)
            data_sources = []
            content.scan(/data\s+:(\w+),\s*:(\w+)/) { |type, name| data_sources << { type: type, name: name } }
            data_sources
          end

          def extract_outputs(content)
            outputs = []
            content.scan(/output\s+:(\w+)/) { |match| outputs << { name: match[0] } }
            outputs
          end

          def extract_locals(content)
            locals = []
            content.scan(/locals\s+do(.*?)end/m) do |match|
              match[0].scan(/(\w+)\s*=/) { |var| locals << { name: var[0] } }
            end
            locals
          end

          def extract_module_calls(content)
            modules = []
            content.scan(/module\s+:(\w+)/) { |match| modules << { name: match[0] } }
            modules
          end

          def extract_resource_functions(content)
            functions = []
            content.scan(/aws_(\w+)\s*\(\s*:(\w+)/) do |resource, name|
              functions << { function: "aws_#{resource}", resource_type: resource, name: name }
            end
            functions
          end

          def extract_architecture_functions(content)
            functions = []
            content.scan(/(\w+_architecture)\s*\(\s*:(\w+)/) do |func, name|
              functions << { function: func, name: name }
            end
            functions
          end

          def extract_component_functions(content)
            functions = []
            content.scan(/(\w+_component)\s*\(\s*:(\w+)/) do |func, name|
              functions << { function: func, name: name }
            end
            functions
          end
        end
      end
    end
  end
