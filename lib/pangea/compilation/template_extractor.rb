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
  module Compilation
    # Handles extraction of templates from Ruby files
    module TemplateExtractor
      # Extract templates from content
      def extract_templates(content)
        content.scan(/template\s+:(\w+)\s+do\s*\n(.*?)\nend/m).to_h do |name, block_content|
          [name.to_sym, clean_template_content(block_content)]
        end
      end
      
      # Process require statements in content
      def process_requires(content, file_path)
        content.scan(/^\s*require\s+['"](.+)['"]/).each do |match|
          load_require(match[0], file_path)
        end
      end
      
      # Filter templates based on template name
      def filter_templates(templates, file_path)
        templates.select { |name, _| name.to_s == @template_name.to_s }
      end
      
      private
      
      # Clean template content by removing extra indentation
      def clean_template_content(block_content)
        lines = block_content.split("\n")
        return "" if lines.empty?
        
        min_indent = calculate_min_indent(lines)
        lines.map { |line| strip_indent(line, min_indent) }.join("\n")
      end
      
      # Calculate minimum indentation level
      def calculate_min_indent(lines)
        lines.reject { |line| line.strip.empty? }
             .map { |line| line[/^\s*/].length }
             .min || 0
      end
      
      # Strip indentation from line
      def strip_indent(line, indent)
        line.strip.empty? ? "" : (line[indent..-1] || line)
      end
      
      # Load required files
      def load_require(require_path, file_path)
        logger = @logger || Logging.logger
        logger.debug "Loading required file", path: require_path
        require require_path
        logger.debug "Successfully loaded", path: require_path
      rescue LoadError => e
        # Try relative to the file's directory
        relative_path = File.join(File.dirname(file_path), require_path)
        logger.debug "Trying relative path", path: relative_path
        require relative_path
        logger.debug "Successfully loaded", path: relative_path
      rescue LoadError => e
        logger.warn "Could not load required file", 
                    path: require_path, 
                    error: e.message
      end
    end
  end
end