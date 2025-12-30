# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  class Agent
    # Template analysis and validation methods
    module Analysis
      def analyze_template(file_path, template_name: nil)
        return error_response("File not found: #{file_path}") unless File.exist?(file_path)

        templates = @compiler.extract_templates(file_path)

        if template_name
          template = templates.find { |t| t[:name].to_s == template_name.to_s }
          return error_response("Template '#{template_name}' not found") unless template

          analyze_single_template(template, file_path)
        else
          { file: file_path, templates: templates.map { |t| analyze_single_template(t, file_path) } }
        end
      rescue StandardError => e
        error_response(e.message)
      end

      def validate_template(file_path, template_name: nil)
        return error_response("File not found: #{file_path}") unless File.exist?(file_path)

        templates = @compiler.extract_templates(file_path)

        validations = templates.map do |template|
          next if template_name && template[:name].to_s != template_name.to_s

          validate_single_template(template, file_path)
        end.compact

        { all_valid: validations.all? { |v| v[:valid] }, validations: validations }
      rescue StandardError => e
        error_response(e.message)
      end

      def get_resource_info(function_name)
        service, resource = parse_function_name(function_name)
        return error_response('Invalid function name') unless service && resource

        file_path = File.join(File.dirname(__FILE__), '..', 'resources', 'aws', service, "#{resource}.rb")
        return error_response('Resource not found') unless File.exist?(file_path)

        { function: function_name, service: service, resource: resource, file: file_path, documentation: extract_documentation(file_path) }
      rescue StandardError => e
        error_response(e.message)
      end

      private

      def analyze_single_template(template, file_path)
        content = template[:content]

        {
          name: template[:name],
          file: file_path,
          line_number: template[:line],
          metrics: {
            lines: content.lines.count,
            resources: count_resources(content),
            outputs: count_outputs(content),
            providers: extract_providers(content)
          },
          resource_functions: extract_resource_functions(content),
          architecture_functions: extract_architecture_functions(content),
          dependencies: extract_dependencies(content)
        }
      end

      def validate_single_template(template, file_path)
        require 'terraform-synthesizer'
        synthesizer = TerraformSynthesizer.new
        synthesizer.instance_eval(template[:content], file_path, template[:line])

        { template: template[:name], valid: true, line_number: template[:line] }
      rescue StandardError => e
        { template: template[:name], valid: false, error: e.message, line_number: template[:line] }
      end

      def count_resources(content)
        content.scan(/resource\s+:/).count + content.scan(/aws_\w+\s*\(/).count
      end

      def count_outputs(content)
        content.scan(/output\s+:/).count
      end

      def extract_providers(content)
        providers = []
        content.scan(/provider\s+:(\w+)/) { |match| providers << match[0] }
        providers.uniq
      end

      def extract_resource_functions(content)
        functions = []
        content.scan(/(aws_\w+)\s*\(\s*:(\w+)/) { |func, name| functions << { function: func, name: name } }
        functions
      end

      def extract_architecture_functions(content)
        functions = []
        content.scan(/(\w+_architecture)\s*\(\s*:(\w+)/) { |func, name| functions << { function: func, name: name } }
        functions
      end

      def extract_dependencies(content)
        refs = []
        content.scan(/ref\(:(\w+),\s*:(\w+),\s*:(\w+)\)/) { |type, name, attr| refs << { type: type, name: name, attribute: attr } }
        refs
      end

      def extract_documentation(file_path)
        content = File.read(file_path)

        if content.match(/^\s*#\s*(.+?)(?:module|class)/m)
          ::Regexp.last_match(1).lines.map(&:strip).map { |l| l.sub(/^#\s*/, '') }.join("\n")
        else
          'No documentation available'
        end
      end
    end
  end
end
