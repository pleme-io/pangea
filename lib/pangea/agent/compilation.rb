# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'json'

module Pangea
  class Agent
    # Template compilation and example generation methods
    module Compilation
      def compile_template(file_path, namespace: nil, template_name: nil)
        return error_response("File not found: #{file_path}") unless File.exist?(file_path)

        namespace ||= Pangea.config.default_namespace
        results = @compiler.compile_file(file_path, namespace: namespace, template: template_name)

        {
          namespace: namespace,
          results: results.map do |result|
            if result[:success]
              { template: result[:name], success: true, terraform_json: JSON.parse(result[:json]) }
            else
              { template: result[:name], success: false, error: result[:error] }
            end
          end
        }
      rescue StandardError => e
        error_response(e.message)
      end

      def generate_example(function_name)
        service, resource = parse_function_name(function_name)
        return error_response('Invalid function name') unless service && resource

        { function: function_name, example: generate_resource_example(function_name, service, resource) }
      end

      private

      def generate_resource_example(function_name, service, resource)
        <<~RUBY
          # Example usage of #{function_name}
          template :example do
            provider :aws do
              region "us-east-1"
            end

            # Create #{resource} in #{service}
            #{function_name}(:my_#{resource}, {
              # Add required attributes here
              name: "example-#{resource}",
              tags: {
                Name: "Example #{resource.gsub('_', ' ').capitalize}",
                Environment: "development"
              }
            })
          end
        RUBY
      end
    end
  end
end
