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

module Pangea
  module CLI
    module UI
      # Template display utilities for consistent template visualization
      module TemplateDisplay
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

            if show_full
              display_full_json(parsed)
            end

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
          backend_config = backend[backend_type]

          formatter.kv_pair('Type', formatter.pastel.cyan(backend_type))

          case backend_type
          when 's3'
            formatter.kv_pair('Bucket', backend_config['bucket'])
            formatter.kv_pair('Key', backend_config['key'])
            formatter.kv_pair('Region', backend_config['region'])
            formatter.kv_pair('DynamoDB Table', backend_config['dynamodb_table']) if backend_config['dynamodb_table']
          when 'local'
            formatter.kv_pair('Path', backend_config['path'])
          end

          formatter.blank_line
        end

        # Display provider configuration
        def display_provider_config(parsed)
          providers = parsed['provider']
          return unless providers

          formatter.subsection_header('Provider Configuration', icon: :provider)

          providers.each do |provider_type, configs|
            configs = [configs] unless configs.is_a?(Array)

            configs.each do |config|
              formatter.list_items([formatter.pastel.cyan(provider_type)])

              if config.is_a?(Hash)
                formatter.kv_pair('Region', config['region'], indent: 4) if config['region']
                formatter.kv_pair('Alias', config['alias'], indent: 4) if config['alias']
              end
            end
          end

          formatter.blank_line
        end

        # Display resources summary with grouping
        def display_resources_summary(parsed)
          resources = extract_resources(parsed)
          return if resources.empty?

          formatter.subsection_header('Resources', icon: :resource)

          # Group by type
          grouped = resources.group_by { |r| r[:type] }

          grouped.sort_by { |type, _| type }.each do |type, type_resources|
            formatter.list_items(
              ["#{formatter.pastel.cyan(type)}: #{type_resources.count}"],
              icon: '•'
            )

            type_resources.each do |resource|
              formatter.kv_pair(resource[:name], '', indent: 4)

              # Show key attributes
              if resource[:attributes].any?
                resource[:attributes].first(2).each do |key, value|
                  formatted_value = format_attribute_value(value)
                  formatter.kv_pair(key.to_s, formatted_value, indent: 6)
                end
              end
            end
          end

          formatter.blank_line
        end

        # Display variables summary
        def display_variables_summary(parsed)
          variables = parsed['variable']
          return unless variables && variables.any?

          formatter.subsection_header('Variables', icon: :config)

          variables.each do |var_name, var_config|
            var_config ||= {}
            description = var_config['description'] || 'No description'
            type_info = var_config['type'] || 'any'

            formatter.list_items(
              ["#{formatter.pastel.cyan(var_name)} (#{type_info}): #{formatter.pastel.bright_black(description)}"],
              icon: '•'
            )
          end

          formatter.blank_line
        end

        # Display outputs summary
        def display_outputs_summary(parsed)
          outputs = parsed['output']
          return unless outputs && outputs.any?

          formatter.subsection_header('Outputs', icon: :output)

          outputs.each do |output_name, output_config|
            output_config ||= {}
            description = output_config['description'] || 'No description'

            formatter.list_items(
              ["#{formatter.pastel.cyan(output_name)}: #{formatter.pastel.bright_black(description)}"],
              icon: '•'
            )
          end

          formatter.blank_line
        end

        # Display full JSON
        def display_full_json(parsed)
          formatter.subsection_header('Full Terraform JSON', icon: :config)
          formatter.separator
          formatter.json_output(parsed)
        end

        # Extract resources from parsed config
        def extract_resources(parsed)
          return [] unless parsed['resource']

          resources = []
          parsed['resource'].each do |resource_type, resource_instances|
            next unless resource_instances.is_a?(Hash)

            resource_instances.each do |resource_name, resource_config|
              next unless resource_config.is_a?(Hash)

              resources << {
                type: resource_type,
                name: resource_name,
                full_name: "#{resource_type}.#{resource_name}",
                config: resource_config,
                attributes: extract_key_attributes(resource_type, resource_config)
              }
            end
          end

          resources
        end

        # Extract key attributes based on resource type
        def extract_key_attributes(resource_type, resource_config)
          key_attrs = {}

          case resource_type
          when /aws_route53_/
            key_attrs[:name] = resource_config['name']
            key_attrs[:type] = resource_config['type']
            key_attrs[:ttl] = resource_config['ttl']
            key_attrs[:records] = resource_config['records']
          when /aws_s3_/
            key_attrs[:bucket] = resource_config['bucket']
            key_attrs[:acl] = resource_config['acl']
          when /aws_lambda_/
            key_attrs[:function_name] = resource_config['function_name']
            key_attrs[:runtime] = resource_config['runtime']
            key_attrs[:handler] = resource_config['handler']
          when /aws_rds_|aws_db_/
            key_attrs[:identifier] = resource_config['identifier']
            key_attrs[:engine] = resource_config['engine']
            key_attrs[:instance_class] = resource_config['instance_class']
          when /aws_ec2_|aws_instance/
            key_attrs[:instance_type] = resource_config['instance_type']
            key_attrs[:ami] = resource_config['ami']
          when /aws_vpc/
            key_attrs[:cidr_block] = resource_config['cidr_block']
          when /aws_subnet/
            key_attrs[:cidr_block] = resource_config['cidr_block']
            key_attrs[:availability_zone] = resource_config['availability_zone']
          else
            # Generic extraction
            %w[name id identifier domain].each do |attr|
              key_attrs[attr.to_sym] = resource_config[attr] if resource_config[attr]
            end
          end

          key_attrs.compact
        end

        # Format attribute value for display
        def format_attribute_value(value)
          case value
          when String
            value.length > 50 ? "#{value[0..47]}..." : value
          when Array
            value.join(', ')
          when Hash
            value.to_json
          else
            value.to_s
          end
        end
      end
    end
  end
end
