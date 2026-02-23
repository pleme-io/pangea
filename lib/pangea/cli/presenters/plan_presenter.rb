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
require 'pangea/cli/ui/diff'
require 'pangea/cli/ui/visualizer'

module Pangea
  module CLI
    module Presenters
      # Plan-specific display logic.
      # Consolidates PlanOutput, ResourceDisplay, JsonFormatting, JsonAnalysis,
      # PlanDisplay, and ActionGroupDisplay.
      class PlanPresenter < BasePresenter
        def initialize(**)
          super
          @diff = UI::Diff::Renderer.new
          @visualizer = UI::Visualizer.new
        end

        # --- JSON Analysis ---

        def analyze_terraform_json(terraform_json)
          config = JSON.parse(terraform_json)
          analysis = {
            providers: extract_providers(config),
            resources: extract_resources(config),
            variables: extract_variables(config),
            outputs: extract_outputs(config),
            backend: extract_backend(config)
          }
          analysis[:summary] = generate_summary(analysis)
          analysis
        rescue JSON::ParserError => e
          ui&.error "Failed to analyze Terraform JSON: #{e.message}"
          { error: e.message }
        end

        # --- Resource Analysis Display ---

        def resource_analysis(template_name, analysis)
          return if analysis[:error]

          ui&.info "\n Template Analysis: #{template_name}"
          ui&.info '-' * 60
          display_analysis_summary(analysis[:summary])
          display_resource_breakdown(analysis[:summary])
          display_key_resources(analysis[:resources])
        end

        # --- Plan Output ---

        def plan_output(plan_result, resource_analysis:)
          formatter.section_header('Execution Plan', icon: :plan)

          if plan_result[:changes]
            display_plan_with_changes(plan_result, resource_analysis)
          else
            display_no_changes_banner(resource_analysis)
          end
        end

        def enhanced_plan_output(plan_result, resource_analysis)
          @diff.terraform_plan(plan_result[:output])

          if plan_result[:resource_changes]
            display_detailed_resource_changes(plan_result[:resource_changes], resource_analysis)
          end

          return unless plan_result[:resource_changes]

          @visualizer.plan_impact(
            create: plan_result[:resource_changes][:create] || [],
            update: plan_result[:resource_changes][:update] || [],
            destroy: plan_result[:resource_changes][:delete] || [],
            details: build_enhanced_change_details(plan_result[:resource_changes], resource_analysis)
          )
        end

        # --- JSON Display ---

        def compiled_json(template_name, terraform_json)
          ui&.info "Compiled Terraform JSON for template '#{template_name}':"
          ui&.info '-' * 60

          parsed = JSON.parse(terraform_json)
          formatted = JSON.pretty_generate(parsed)

          formatted.lines.each_with_index do |line, index|
            line_number = (index + 1).to_s.rjust(4)
            ui&.say "#{Boreal.paint(line_number, :muted)} #{highlight_json_line(line.chomp)}"
          end
        rescue JSON::ParserError
          ui&.error 'Invalid JSON in compiled output'
          ui&.say terraform_json
        end

        # --- State Display ---

        def no_changes(template_name, executor, resource_analysis)
          ui&.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
          display_current_state(executor, resource_analysis)
        end

        def plan_failure(template_name, plan_result)
          ui&.error "Planning failed for template '#{template_name}':"
          ui&.error plan_result[:error] if plan_result[:error]
          ui&.error plan_result[:output] if plan_result[:output] && !plan_result[:output].empty?
        end

        def successful_plan(template_name, workspace, plan_result, resource_analysis, file_path:, namespace:, template_flag: nil)
          ui&.success "Plan generated for template '#{template_name}'"
          ui&.info "Plan saved to: #{File.join(workspace, 'plan.tfplan')}"
          enhanced_plan_output(plan_result, resource_analysis)
          ui&.info "\nWorkspace: #{workspace}"
          ui&.info "\nTo apply these changes, run:"
          flag = template_flag ? " --template #{template_flag}" : ''
          ui&.info "  pangea apply #{file_path} --namespace #{namespace}#{flag}"
        end

        private

        # --- Extraction helpers ---

        def extract_providers(config)
          return [] unless config['provider']

          result = []
          config['provider'].each do |type, cfgs|
            Array(cfgs.is_a?(Array) ? cfgs : [cfgs]).each do |cfg|
              result << { type: type, alias: cfg&.dig('alias'), region: cfg&.dig('region'), config: cfg }
            end
          end
          result
        end

        def extract_resources(config)
          return [] unless config['resource']

          resources = []
          config['resource'].each do |rtype, instances|
            next unless instances.is_a?(Hash)

            instances.each do |rname, rcfg|
              next unless rcfg.is_a?(Hash)

              resources << {
                type: rtype, name: rname, full_name: "#{rtype}.#{rname}",
                config: rcfg, attributes: extract_key_attributes(rtype, rcfg)
              }
            end
          end
          resources
        end

        def extract_variables(config)
          return [] unless config['variable']&.is_a?(Hash)

          config['variable'].map do |name, cfg|
            cfg = {} unless cfg.is_a?(Hash)
            { name: name, type: cfg['type'], description: cfg['description'], default: cfg['default'] }
          end
        end

        def extract_outputs(config)
          return [] unless config['output']&.is_a?(Hash)

          config['output'].map do |name, cfg|
            cfg = {} unless cfg.is_a?(Hash)
            { name: name, description: cfg['description'], value: cfg['value'] }
          end
        end

        def extract_backend(config)
          return nil unless config.dig('terraform', 'backend')

          btype = config['terraform']['backend'].keys.first
          { type: btype, config: config['terraform']['backend'][btype] }
        end

        def extract_key_attributes(resource_type, resource_config)
          attrs = {}
          case resource_type
          when /aws_route53_/
            attrs[:domain] = resource_config['name']
            attrs[:type] = resource_config['type']
            attrs[:ttl] = resource_config['ttl']
            attrs[:records] = resource_config['records']
          when /aws_s3_/
            attrs[:bucket] = resource_config['bucket']
          when /aws_lambda_/
            attrs[:function_name] = resource_config['function_name']
            attrs[:runtime] = resource_config['runtime']
          when /aws_rds_/
            attrs[:identifier] = resource_config['identifier']
            attrs[:engine] = resource_config['engine']
          else
            %w[name id identifier domain].each { |a| attrs[a.to_sym] = resource_config[a] if resource_config[a] }
          end
          attrs
        end

        def generate_summary(analysis)
          {
            total_resources: analysis[:resources].count,
            resource_types: analysis[:resources].group_by { |r| r[:type] }.transform_values(&:count),
            providers: analysis[:providers].map { |p| p[:type] }.uniq,
            has_backend: !analysis[:backend].nil?,
            variables_count: analysis[:variables].count,
            outputs_count: analysis[:outputs].count,
            estimated_cost: estimate_monthly_cost(analysis[:resources])
          }
        end

        def estimate_monthly_cost(resources)
          total = resources.sum do |r|
            case r[:type]
            when 'aws_route53_zone' then 0.50
            when 'aws_route53_record' then 0.001
            when 'aws_s3_bucket' then 5.00
            when 'aws_lambda_function' then 10.00
            when 'aws_rds_cluster' then 100.00
            else 1.00
            end
          end
          total.round(2)
        end

        # --- Display helpers ---

        def display_analysis_summary(summary)
          ui&.info ' Summary:'
          ui&.say "  * #{Boreal.bold(summary[:total_resources])} resources defined"
          ui&.say "  * #{Boreal.bold(summary[:providers].count)} provider(s): #{summary[:providers].join(', ')}"
          ui&.say "  * #{Boreal.bold(summary[:variables_count])} variables"
          ui&.say "  * #{Boreal.bold(summary[:outputs_count])} outputs"
          ui&.say "  * Backend: #{summary[:has_backend] ? Boreal.paint('configured', :success) : Boreal.paint('local', :update)}"
          ui&.say "  * Estimated cost: #{Boreal.paint("$#{summary[:estimated_cost]}/month", :primary)}"
        end

        def display_resource_breakdown(summary)
          return unless summary[:resource_types].any?

          ui&.info "\n  Resources by type:"
          summary[:resource_types].sort_by { |_, c| -c }.each do |type, count|
            ui&.say "  * #{Boreal.paint(type, :primary)}: #{count}"
          end
        end

        def display_key_resources(resources)
          return if resources.empty?

          ui&.info "\n Resource Details:"
          resources.each do |resource|
            ui&.say "  * #{Boreal.bold(resource[:full_name])}"
            resource[:attributes].each do |key, value|
              next if value.nil? || value.to_s.empty?

              ui&.say "    #{key}: #{Boreal.paint(format_attribute_value(value), :muted)}"
            end
          end
        end

        def display_plan_with_changes(plan_result, resource_analysis)
          if plan_result[:output]
            @diff.terraform_plan(plan_result[:output])
          end

          if plan_result[:resource_changes]
            display_resource_change_groups(plan_result[:resource_changes], resource_analysis)
            display_impact_visualization(plan_result[:resource_changes])
          end
        end

        def display_no_changes_banner(resource_analysis)
          formatter.status(:success, 'No changes required')
          formatter.kv_pair('Status', Boreal.paint('Infrastructure is up-to-date', :success))
          if resource_analysis && resource_analysis[:resources]
            formatter.kv_pair('Resources managed', Boreal.paint(resource_analysis[:resources].count.to_s, :primary))
          end
          formatter.blank_line
        end

        def display_resource_change_groups(changes, resource_analysis)
          formatter.subsection_header('Resource Changes', icon: :diff)

          total = 0
          %i[create update delete replace].each do |action|
            next unless changes[action]&.any?

            display_action_group(action, changes[action], resource_analysis)
            total += changes[action].count
          end

          formatter.blank_line
          formatter.kv_pair('Total changes', Boreal.bold("#{total} resource(s) will be modified"))
          formatter.blank_line
        end

        def display_action_group(action, resources, resource_analysis)
          color, icon = action_style(action)
          formatter.list_items(
            ["#{Boreal.paint("#{icon} #{action.to_s.upcase}", color)}: #{resources.count} resource(s)"],
            icon: icon
          )
          resources.each do |ref|
            formatter.kv_pair('  ', Boreal.paint(ref, color))
          end
        end

        def display_impact_visualization(changes)
          @visualizer.plan_impact(
            create: changes[:create] || [],
            update: changes[:update] || [],
            destroy: changes[:delete] || []
          )
        end

        def action_style(action)
          case action
          when :create  then [:create, '+']
          when :update  then [:update, '~']
          when :delete  then [:delete, '-']
          when :replace then [:replace, '+/-']
          end
        end

        def display_detailed_resource_changes(changes, resource_analysis)
          ui&.info "\n Detailed Resource Changes:"
          ui&.info '-' * 60

          %i[create update delete replace].each do |action|
            next unless changes[action]&.any?

            color, icon = action_style(action)
            ui&.say "\n#{Boreal.paint("#{icon} #{action.to_s.upcase}:", color)}"

            changes[action].each do |ref|
              info = find_resource_info(ref, resource_analysis)
              if info
                ui&.say "  * #{Boreal.bold(ref)}"
                display_action_detail(info, action)
              else
                ui&.say "  * #{ref}"
              end
            end
          end
        end

        def display_action_detail(info, action)
          case action
          when :create
            ui&.say "    -> Creating new #{info[:type]}"
            display_inline_attributes(info[:attributes])
          when :delete
            ui&.say "    -> #{Boreal.paint('Warning: Will destroy existing resource', :error)}"
            display_inline_attributes(info[:attributes])
          when :update
            ui&.say "    -> Modifying existing #{info[:type]}"
          when :replace
            ui&.say "    -> #{Boreal.paint('Warning: Will replace (destroy + create)', :replace)}"
            display_inline_attributes(info[:attributes])
          end
        end

        def display_inline_attributes(attributes)
          return if attributes.empty?

          attributes.each do |key, value|
            next if value.nil? || value.to_s.empty?

            ui&.say "      #{key}: #{Boreal.paint(format_attribute_value(value), :muted)}"
          end
        end

        def build_enhanced_change_details(changes, resource_analysis)
          details = {}
          %i[create update destroy].each do |action|
            next unless changes[action]

            details[action] = changes[action].map do |ref|
              info = find_resource_info(ref, resource_analysis)
              if info
                { type: info[:type], name: info[:name], attributes: info[:attributes] }
              else
                type, name = ref.split('.', 2)
                { type: type, name: name }
              end
            end
          end
          details
        end

        def find_resource_info(ref, resource_analysis)
          return nil unless resource_analysis && resource_analysis[:resources]

          resource_analysis[:resources].find { |r| r[:full_name] == ref }
        end

        def display_current_state(executor, resource_analysis)
          ui&.info "\n Current Infrastructure State:"
          ui&.info '-' * 60

          state_result = executor.state_list
          if state_result[:success] && state_result[:resources]
            ui&.info "#{state_result[:resources].count} resources currently managed"
            grouped = state_result[:resources].group_by { |r| r.split('.').first }
            grouped.each do |type, items|
              ui&.say "  * #{Boreal.paint(type, :primary)}: #{items.count} instance(s)"
            end
          else
            ui&.info 'No existing state found - this will be a fresh deployment'
          end

          if resource_analysis[:resources]&.any?
            ui&.info "\n Resources defined in template:"
            resource_analysis[:resources].each do |r|
              ui&.say "  * #{Boreal.paint(r[:full_name], :muted)}"
            end
          end
        end

        def format_attribute_value(value)
          case value
          when Array  then value.join(', ')
          when Hash   then value.to_json
          when String then value.length > 50 ? "#{value[0..47]}..." : value
          else value.to_s
          end
        end

        def highlight_json_line(line)
          line
            .gsub(/"([^"]+)":/, Boreal.paint("\"\\1\":", :info))
            .gsub(/:\s*"([^"]+)"/, ": #{Boreal.paint("\"\\1\"", :success)}")
            .gsub(/:\s*(\d+)/, ": #{Boreal.paint('\\1', :primary)}")
            .gsub(/:\s*(true|false)/, ": #{Boreal.paint('\\1', :update)}")
            .gsub(/([{}\[\],])/, Boreal.paint('\\1', :muted))
        end
      end
    end
  end
end
