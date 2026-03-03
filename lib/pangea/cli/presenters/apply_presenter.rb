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
    module Presenters
      # Apply-specific display logic.
      # Consolidates TemplateDisplay + apply display methods.
      class ApplyPresenter < BasePresenter
        # Display compiled template with full details. Returns parsed JSON or nil.
        def compiled_template(template_name, terraform_json, show_full: false)
          formatter.section_header("Compiled Template: #{template_name}", icon: :template)

          parsed = JSON.parse(terraform_json)

          template_metadata(template_name, parsed)
          backend_config(parsed)
          provider_config(parsed)
          resources_summary(parsed)
          variables_summary(parsed)
          outputs_summary(parsed)
          full_json(parsed) if show_full

          parsed
        rescue JSON::ParserError => e
          formatter.status(:error, "Failed to parse template: #{e.message}")
          nil
        end

        # Display the execution plan (delegates to PlanDisplay-style formatting).
        def plan(plan_result, resource_analysis: nil)
          formatter.section_header('Execution Plan', icon: :plan)

          if plan_result[:changes]
            plan_with_changes(plan_result, resource_analysis)
          else
            no_changes_banner(resource_analysis)
          end
        end

        def confirmation_prompt(action: 'apply', timeout: 5)
          formatter.blank_line
          formatter.status(
            :warning,
            "Changes will be #{action}ed. Press Ctrl+C within #{timeout} seconds to cancel..."
          )
        end

        def apply_success(template_name, apply_result, resource_analysis, namespace:)
          operation_success('Apply', details: {
            'Template' => template_name,
            'Namespace' => namespace,
            'Resources managed' => (resource_analysis[:resources]&.count || 0).to_s
          })

          changes_summary(
            added: apply_result[:added] || 0,
            changed: apply_result[:changed] || 0,
            destroyed: apply_result[:destroyed] || 0
          )
        end

        private

        def template_metadata(template_name, parsed)
          formatter.subsection_header('Template Information', icon: :info)
          resource_count = parsed.dig('resource')&.values&.flat_map(&:keys)&.count || 0
          provider_count = parsed.dig('provider')&.keys&.count || 0
          formatter.kv_pair('Name', Boreal.bold(template_name))
          formatter.kv_pair('Resources', Boreal.paint(resource_count.to_s, :primary))
          formatter.kv_pair('Providers', Boreal.paint(provider_count.to_s, :primary))
          formatter.blank_line
        end

        def backend_config(parsed)
          backend = parsed.dig('terraform', 'backend')
          return unless backend

          formatter.subsection_header('Backend Configuration', icon: :backend)
          btype = backend.keys.first
          formatter.kv_pair('Type', Boreal.paint(btype, :primary))
          backend_type_config(btype, backend[btype])
          formatter.blank_line
        end

        def provider_config(parsed)
          providers = parsed['provider']
          return unless providers

          formatter.subsection_header('Provider Configuration', icon: :provider)
          providers.each do |ptype, cfgs|
            Array(cfgs).each { |cfg| single_provider(ptype, cfg) }
          end
          formatter.blank_line
        end

        def resources_summary(parsed)
          resources = extract_resources(parsed)
          return if resources.empty?

          formatter.subsection_header('Resources', icon: :resource)
          resources.group_by { |r| r[:type] }.sort_by { |t, _| t }.each do |type, items|
            resource_type_group(type, items)
          end
          formatter.blank_line
        end

        def variables_summary(parsed)
          variables = parsed['variable']
          return unless variables&.any?

          formatter.subsection_header('Variables', icon: :config)
          variables.each do |name, cfg|
            desc = (cfg || {})['description'] || 'No description'
            type_info = (cfg || {})['type'] || 'any'
            list_item("#{name} (#{type_info})", desc)
          end
          formatter.blank_line
        end

        def outputs_summary(parsed)
          outputs = parsed['output']
          return unless outputs&.any?

          formatter.subsection_header('Outputs', icon: :output)
          outputs.each do |name, cfg|
            list_item(name, (cfg || {})['description'] || 'No description')
          end
          formatter.blank_line
        end

        def full_json(parsed)
          formatter.subsection_header('Full Terraform JSON', icon: :config)
          formatter.separator
          formatter.json_output(parsed)
        end

        def extract_resources(parsed)
          return [] unless parsed['resource']

          resources = []
          parsed['resource'].each do |rtype, instances|
            next unless instances.is_a?(Hash)

            instances.each do |rname, rcfg|
              next unless rcfg.is_a?(Hash)

              attrs = {}
              %w[bucket domain function_name identifier name].each do |a|
                attrs[a.to_sym] = rcfg[a] if rcfg[a]
              end
              resources << { type: rtype, name: rname, full_name: "#{rtype}.#{rname}", attributes: attrs }
            end
          end
          resources
        end

        def plan_with_changes(plan_result, resource_analysis)
          if plan_result[:output]
            diff = UI::Diff::Renderer.new
            diff.terraform_plan(plan_result[:output])
          end

          return unless plan_result[:resource_changes]

          formatter.subsection_header('Resource Changes', icon: :diff)
          total = 0
          %i[create update delete replace].each do |action|
            next unless plan_result[:resource_changes][action]&.any?

            items = plan_result[:resource_changes][action]
            color = action_color(action)
            formatter.list_items(
              ["#{Boreal.paint(action.to_s.upcase, color)}: #{items.count} resource(s)"]
            )
            total += items.count
          end
          formatter.kv_pair('Total', "#{total} resource(s) will be modified")
          formatter.blank_line
        end

        def no_changes_banner(resource_analysis)
          formatter.status(:success, 'No changes required')
          formatter.kv_pair('Status', Boreal.paint('Infrastructure is up-to-date', :success))
          if resource_analysis && resource_analysis[:resources]
            formatter.kv_pair('Resources managed', Boreal.paint(resource_analysis[:resources].count.to_s, :primary))
          end
          formatter.blank_line
        end

        def action_color(action)
          case action
          when :create  then :create
          when :update  then :update
          when :delete  then :delete
          when :replace then :replace
          end
        end

        def backend_type_config(btype, bcfg)
          case btype
          when 's3'
            formatter.kv_pair('Bucket', bcfg['bucket'])
            formatter.kv_pair('Key', bcfg['key'])
            formatter.kv_pair('Region', bcfg['region'])
            formatter.kv_pair('DynamoDB Table', bcfg['dynamodb_table']) if bcfg['dynamodb_table']
          when 'local'
            formatter.kv_pair('Path', bcfg['path'])
          end
        end

        def single_provider(ptype, config)
          formatter.list_items([Boreal.paint(ptype, :primary)])
          return unless config.is_a?(Hash)

          formatter.kv_pair('Region', config['region'], indent: 4) if config['region']
          formatter.kv_pair('Alias', config['alias'], indent: 4) if config['alias']
        end

        def resource_type_group(type, items)
          formatter.list_items(["#{Boreal.paint(type, :primary)}: #{items.count}"], icon: '•')
          items.each do |resource|
            formatter.kv_pair(resource[:name], '', indent: 4)
            resource[:attributes].first(2).each do |key, value|
              formatter.kv_pair(key.to_s, format_attr(value), indent: 6)
            end
          end
        end

        def list_item(name, description)
          formatter.list_items(
            ["#{Boreal.paint(name, :primary)}: #{Boreal.paint(description, :muted)}"],
            icon: '•'
          )
        end

        def format_attr(value)
          case value
          when Array  then value.join(', ')
          when Hash   then value.to_json
          when String then value.length > 50 ? "#{value[0..47]}..." : value
          else value.to_s
          end
        end
      end
    end
  end
end
