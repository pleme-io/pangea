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

require 'json'
require 'pangea/cli/ui/output_formatter'
require_relative 'template_display/resource_extractor'

module Pangea
  module CLI
    module UI
      # Template display utilities for consistent template visualization
      module TemplateDisplay
        include ResourceExtractor

        def formatter
          @formatter ||= OutputFormatter.new
        end

        # Display compiled template with full details
        def display_compiled_template(template_name, terraform_json, show_full: false)
          formatter.section_header("Compiled Template: #{template_name}", icon: :template)

          begin
            parsed = JSON.parse(terraform_json)

            display_template_metadata(template_name, parsed)
            display_backend_config(parsed)
            display_provider_config(parsed)
            display_resources_summary(parsed)
            display_variables_summary(parsed)
            display_outputs_summary(parsed)

            display_full_json(parsed) if show_full

            parsed
          rescue JSON::ParserError => e
            formatter.status(:error, "Failed to parse template: #{e.message}")
            nil
          end
        end

        # Display template metadata
        def display_template_metadata(template_name, parsed)
          formatter.subsection_header('Template Information', icon: :info)
          resource_count = parsed.dig('resource')&.values&.flat_map(&:keys)&.count || 0
          provider_count = parsed.dig('provider')&.keys&.count || 0
          formatter.kv_pair('Name', formatter.pastel.bold(template_name))
          formatter.kv_pair('Resources', formatter.pastel.cyan(resource_count.to_s))
          formatter.kv_pair('Providers', formatter.pastel.cyan(provider_count.to_s))
          formatter.blank_line
        end

        # Display backend configuration
        def display_backend_config(parsed)
          backend = parsed.dig('terraform', 'backend')
          return unless backend

          formatter.subsection_header('Backend Configuration', icon: :backend)
          backend_type = backend.keys.first
          formatter.kv_pair('Type', formatter.pastel.cyan(backend_type))
          display_backend_type_config(backend_type, backend[backend_type])
          formatter.blank_line
        end

        # Display provider configuration
        def display_provider_config(parsed)
          providers = parsed['provider']
          return unless providers

          formatter.subsection_header('Provider Configuration', icon: :provider)
          providers.each do |provider_type, configs|
            Array(configs).each { |config| display_single_provider(provider_type, config) }
          end
          formatter.blank_line
        end

        # Display resources summary with grouping
        def display_resources_summary(parsed)
          resources = extract_resources(parsed)
          return if resources.empty?

          formatter.subsection_header('Resources', icon: :resource)
          resources.group_by { |r| r[:type] }.sort_by { |type, _| type }.each do |type, items|
            display_resource_type_group(type, items)
          end
          formatter.blank_line
        end

        # Display variables summary
        def display_variables_summary(parsed)
          variables = parsed['variable']
          return unless variables&.any?

          formatter.subsection_header('Variables', icon: :config)
          variables.each do |var_name, cfg|
            desc = (cfg || {})['description'] || 'No description'
            type_info = (cfg || {})['type'] || 'any'
            display_list_item("#{var_name} (#{type_info})", desc)
          end
          formatter.blank_line
        end

        # Display outputs summary
        def display_outputs_summary(parsed)
          outputs = parsed['output']
          return unless outputs&.any?

          formatter.subsection_header('Outputs', icon: :output)
          outputs.each do |name, cfg|
            display_list_item(name, (cfg || {})['description'] || 'No description')
          end
          formatter.blank_line
        end

        # Display full JSON
        def display_full_json(parsed)
          formatter.subsection_header('Full Terraform JSON', icon: :config)
          formatter.separator
          formatter.json_output(parsed)
        end

        private

        def display_backend_type_config(backend_type, backend_config)
          case backend_type
          when 's3'
            formatter.kv_pair('Bucket', backend_config['bucket'])
            formatter.kv_pair('Key', backend_config['key'])
            formatter.kv_pair('Region', backend_config['region'])
            formatter.kv_pair('DynamoDB Table', backend_config['dynamodb_table']) if backend_config['dynamodb_table']
          when 'local'
            formatter.kv_pair('Path', backend_config['path'])
          end
        end

        def display_single_provider(provider_type, config)
          formatter.list_items([formatter.pastel.cyan(provider_type)])

          return unless config.is_a?(Hash)

          formatter.kv_pair('Region', config['region'], indent: 4) if config['region']
          formatter.kv_pair('Alias', config['alias'], indent: 4) if config['alias']
        end

        def display_resource_type_group(type, type_resources)
          formatter.list_items(
            ["#{formatter.pastel.cyan(type)}: #{type_resources.count}"],
            icon: '•'
          )

          type_resources.each do |resource|
            formatter.kv_pair(resource[:name], '', indent: 4)
            display_resource_attributes(resource[:attributes])
          end
        end

        def display_resource_attributes(attributes)
          return unless attributes.any?

          attributes.first(2).each do |key, value|
            formatted_value = format_attribute_value(value)
            formatter.kv_pair(key.to_s, formatted_value, indent: 6)
          end
        end
      end
    end
  end
end
