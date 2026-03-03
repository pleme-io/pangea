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

require 'terraform-synthesizer'
require 'json'
require 'pangea/types'
require 'pangea/entities'
require 'parallel'
require 'pangea/logging'
require 'pangea/compilation/template_extractor'
require 'pangea/compilation/backend_injector'
require 'pangea/compilation/template_validator'
require 'pangea/compilation/compilation_helpers'

module Pangea
  module Compilation
    # Compiles Ruby DSL templates into Terraform JSON
    class TemplateCompiler
      include TemplateExtractor
      include BackendInjector
      include TemplateValidator
      include CompilationHelpers
      
      attr_reader :synthesizer, :namespace
      
      def initialize(namespace: nil, template_name: nil)
        @synthesizer = TerraformSynthesizer.new
        @namespace = namespace
        @template_name = template_name
        @templates = {}
        @logger = Logging.logger.child(
          component: 'TemplateCompiler',
          namespace: namespace,
          template: template_name
        )
      end
      
      # Compile templates from a file
      def compile_file(file_path)
        @logger.measure("compile_file", file: file_path) do
          validate_file!(file_path)
          
          content = File.read(file_path)
          @logger.debug "Read file content", size: content.size, lines: content.lines.count
          
          process_requires(content, file_path)
          
          template_blocks = extract_templates(content)
          @logger.info "Extracted templates", count: template_blocks.size, templates: template_blocks.keys
          
          template_blocks = filter_templates(template_blocks, file_path) if @template_name
          
          return template_not_found_error(file_path) if @template_name && template_blocks.empty?
          
          results = compile_all_templates(template_blocks, file_path)
          format_compilation_results(results, template_blocks)
        end
      end
      
      private
      
      def compile_all_templates(template_blocks, file_path)
        # Use parallel processing for multiple templates
        if template_blocks.size > 1 && !ENV['PANGEA_NO_PARALLEL']
          compile_templates_parallel(template_blocks, file_path)
        else
          compile_templates_sequential(template_blocks, file_path)
        end
      end
      
      def compile_templates_parallel(template_blocks, file_path)
        # Determine thread count based on templates and CPU cores
        thread_count = [template_blocks.size, Parallel.processor_count, 4].min
        @logger.info "Compiling templates in parallel", 
                     template_count: template_blocks.size, 
                     thread_count: thread_count,
                     cpu_count: Parallel.processor_count
        
        results = Parallel.map(template_blocks, in_threads: thread_count) do |name, block_content|
          [name, compile_template(name, block_content, file_path)]
        end
        
        results.to_h
      end
      
      def compile_templates_sequential(template_blocks, file_path)
        template_blocks.map { |name, block_content| 
          [name, compile_template(name, block_content, file_path)] 
        }.to_h
      end
      
      def format_compilation_results(results, template_blocks)
        return results[template_blocks.keys.first] if @template_name
        return results.values.first if results.count == 1
        combine_results(results)
      end
      
      # Compile a single template block
      def compile_template(name, content, source_file)
        template_logger = @logger.child(template_name: name)
        
        template_logger.measure("compile_template") do
          compile_template_internal(name, content, source_file, template_logger)
        end
      end
    end
    
    # Compilation-specific errors
    class CompilationError < StandardError; end
  end
end