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

require 'pangea/compilation/template_compiler'

module Pangea
  module CLI
    module Services
      # Compiles and iterates Pangea templates.
      # Replaces the TemplateProcessor mixin.
      class TemplateService
        def initialize(ui:)
          @ui = ui
        end

        # Compile a single file, yielding each template name + JSON.
        def process_all(file_path:, namespace:, template_name: nil, &block)
          result = compile(file_path: file_path, namespace: namespace, template_name: template_name)

          unless result.success
            @ui.error "Compilation failed:"
            result.errors.each { |err| @ui.error "  #{err}" }
            return
          end

          display_warnings(result.warnings) if result.warnings.any?

          if template_name
            yield(template_name, result.terraform_json)
          elsif result.template_count && result.template_count > 1
            compile_each(file_path, namespace, result, &block)
          else
            name = result.template_name || extract_project_from_file(file_path)
            yield(name, result.terraform_json)
          end
        end

        # Compile and return the raw CompilationResult.
        def compile(file_path:, namespace:, template_name: nil)
          compiler = Compilation::TemplateCompiler.new(
            namespace: namespace,
            template_name: template_name
          )
          compiler.compile_file(file_path)
        rescue StandardError => e
          Entities::CompilationResult.new(success: false, errors: [e.message])
        end

        private

        def compile_each(file_path, namespace, result)
          @ui.info "Multiple templates found. Processing all templates..."

          names = result.template_name.gsub('Multiple templates: ', '').split(', ')

          names.each do |name|
            @ui.info "\nProcessing template: #{name}"
            template_result = compile(file_path: file_path, namespace: namespace, template_name: name)

            if template_result.success
              yield(name, template_result.terraform_json)
            else
              @ui.error "Failed to compile template '#{name}':"
              template_result.errors.each { |err| @ui.error "  #{err}" }
            end
          end

          @ui.info "\nAll templates processed."
        end

        def extract_project_from_file(file_path)
          basename = File.basename(file_path, '.*')
          basename == 'main' ? nil : basename
        end

        def display_warnings(warnings)
          @ui.warn "Compilation warnings:"
          warnings.each { |w| @ui.warn "  #{w}" }
        end
      end
    end
  end
end
