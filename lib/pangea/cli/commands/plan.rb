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


require 'pangea/cli/commands/base_command'
require 'pangea/cli/commands/template_processor'
require 'pangea/cli/commands/workspace_operations'
require 'pangea/compilation/validator'
require 'pangea/execution/terraform_executor'
require 'pangea/execution/workspace_manager'
require 'pangea/backends'
require 'pangea/cli/ui/diff'
require 'pangea/cli/ui/progress'
require 'pangea/cli/ui/visualizer'
require 'json'

module Pangea
  module CLI
    module Commands
      # Plan command - show what changes would be made
      class Plan < BaseCommand
        include TemplateProcessor
        include WorkspaceOperations
        
        def run(file_path, namespace:, template: nil, show_compiled: false)
          @workspace_manager = Execution::WorkspaceManager.new
          @diff = UI::Diff.new
          @visualizer = UI::Visualizer.new
          @progress = UI::Progress.new
          @namespace = namespace
          @file_path = file_path
          @show_compiled = show_compiled
          
          # Load namespace configuration
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity
          
          # Process templates using shared logic
          process_templates(
            file_path: file_path,
            namespace: namespace,
            template_name: template
          ) do |template_name, terraform_json|
            plan_template(template_name, terraform_json, namespace_entity)
          end
        end
        
        def plan_template(template_name, terraform_json, namespace_entity)
          # Show compiled Terraform JSON if requested
          if @show_compiled
            display_compiled_json(template_name, terraform_json)
            return
          end
          
          # Analyze compiled resources before planning
          resource_analysis = analyze_terraform_json(terraform_json)
          display_resource_analysis(template_name, resource_analysis)
          
          # Set up workspace
          workspace = setup_workspace(
            template_name: template_name,
            terraform_json: terraform_json,
            namespace: @namespace,
            source_file: @file_path
          )
          
          # Initialize if needed
          return unless ensure_initialized(workspace)
          
          executor = Execution::TerraformExecutor.new(working_dir: workspace)
          
          # Run plan
          plan_file = File.join(workspace, 'plan.tfplan')
          plan_result = with_spinner("Planning changes...") do
            executor.plan(out_file: plan_file)
          end
          
          if plan_result[:success]
            if plan_result[:changes]
              ui.success "Plan generated for template '#{template_name}'"
              ui.info "Plan saved to: #{plan_file}"
              
              # Enhanced plan output with resource details
              display_enhanced_plan_output(plan_result, resource_analysis)
              
              ui.info "\nWorkspace: #{workspace}"
              ui.info "\nTo apply these changes, run:"
              template_flag = @template ? " --template #{@template}" : ""
              ui.info "  pangea apply #{@file_path} --namespace #{@namespace}#{template_flag}"
            else
              ui.info "No changes required for template '#{template_name}'. Infrastructure is up-to-date."
              display_current_state(executor, resource_analysis)
            end
          else
            ui.error "Planning failed for template '#{template_name}':"
            ui.error plan_result[:error] if plan_result[:error]
            ui.error plan_result[:output] if plan_result[:output] && !plan_result[:output].empty?
          end
        end
        
        private
        
        def display_compiled_json(template_name, terraform_json)
          ui.info "Compiled Terraform JSON for template '#{template_name}':"
          ui.info "─" * 60
          
          # Pretty print the JSON with syntax highlighting
          begin
            parsed = JSON.parse(terraform_json)
            formatted_json = JSON.pretty_generate(parsed)
            
            # Display with basic syntax highlighting
            formatted_json.lines.each_with_index do |line, index|
              line_number = (index + 1).to_s.rjust(4)
              ui.say "#{ui.pastel.bright_black(line_number)} #{highlight_json_line(line.chomp)}"
            end
          rescue JSON::ParserError
            ui.error "Invalid JSON in compiled output"
            ui.say terraform_json
          end
        end
        
        def analyze_terraform_json(terraform_json)
          begin
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
            ui.error "Failed to analyze Terraform JSON: #{e.message}"
            { error: e.message }
          end
        end
        
        def extract_providers(config)
          return [] unless config['provider']
          
          result = []
          config['provider'].each do |provider_type, provider_configs|
            # Handle case where provider_configs might not be an array
            configs = provider_configs.is_a?(Array) ? provider_configs : [provider_configs]
            
            configs.each do |provider_config|
              result << {
                type: provider_type,
                alias: provider_config&.dig('alias'),
                region: provider_config&.dig('region'),
                config: provider_config
              }
            end
          end
          result
        end
        
        def extract_resources(config)
          return [] unless config['resource']
          
          resources = []
          config['resource'].each do |resource_type, resource_instances|
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
        
        def extract_variables(config)
          return [] unless config['variable']&.is_a?(Hash)
          
          config['variable'].map do |var_name, var_config|
            var_config = {} unless var_config.is_a?(Hash)
            {
              name: var_name,
              type: var_config['type'],
              description: var_config['description'],
              default: var_config['default']
            }
          end
        end
        
        def extract_outputs(config)
          return [] unless config['output']&.is_a?(Hash)
          
          config['output'].map do |output_name, output_config|
            output_config = {} unless output_config.is_a?(Hash)
            {
              name: output_name,
              description: output_config['description'],
              value: output_config['value']
            }
          end
        end
        
        def extract_backend(config)
          return nil unless config['terraform'] && config['terraform']['backend']
          
          backend_type = config['terraform']['backend'].keys.first
          backend_config = config['terraform']['backend'][backend_type]
          
          {
            type: backend_type,
            config: backend_config
          }
        end
        
        def extract_key_attributes(resource_type, resource_config)
          # Extract key identifying attributes based on resource type
          key_attrs = {}
          
          case resource_type
          when /aws_route53_/
            key_attrs[:domain] = resource_config['name']
            key_attrs[:type] = resource_config['type']
            key_attrs[:ttl] = resource_config['ttl']
            key_attrs[:records] = resource_config['records']
          when /aws_s3_/
            key_attrs[:bucket] = resource_config['bucket']
          when /aws_lambda_/
            key_attrs[:function_name] = resource_config['function_name']
            key_attrs[:runtime] = resource_config['runtime']
          when /aws_rds_/
            key_attrs[:identifier] = resource_config['identifier']
            key_attrs[:engine] = resource_config['engine']
          else
            # Generic extraction
            %w[name id identifier domain].each do |attr|
              key_attrs[attr.to_sym] = resource_config[attr] if resource_config[attr]
            end
          end
          
          key_attrs
        end
        
        def generate_summary(analysis)
          summary = {
            total_resources: analysis[:resources].count,
            resource_types: analysis[:resources].group_by { |r| r[:type] }.transform_values(&:count),
            providers: analysis[:providers].map { |p| p[:type] }.uniq,
            has_backend: !analysis[:backend].nil?,
            variables_count: analysis[:variables].count,
            outputs_count: analysis[:outputs].count
          }
          
          # Add cost estimation
          summary[:estimated_cost] = estimate_monthly_cost(analysis[:resources])
          
          summary
        end
        
        def estimate_monthly_cost(resources)
          total = 0.0
          
          resources.each do |resource|
            cost = case resource[:type]
                   when 'aws_route53_zone'
                     0.50  # $0.50 per hosted zone per month
                   when 'aws_route53_record'
                     0.001 # Minimal cost for DNS queries
                   when 'aws_s3_bucket'
                     5.00  # Estimated based on moderate usage
                   when 'aws_lambda_function'
                     10.00 # Estimated based on moderate usage
                   when 'aws_rds_cluster'
                     100.00 # Estimated for small instance
                   else
                     1.00  # Default small cost for unknown resources
                   end
            total += cost
          end
          
          total.round(2)
        end
        
        def display_resource_analysis(template_name, analysis)
          return if analysis[:error]
          
          ui.info "\n📋 Template Analysis: #{template_name}"
          ui.info "─" * 60
          
          summary = analysis[:summary]
          
          # Summary section
          ui.info "📊 Summary:"
          ui.say "  • #{ui.pastel.bold(summary[:total_resources])} resources defined"
          ui.say "  • #{ui.pastel.bold(summary[:providers].count)} provider(s): #{summary[:providers].join(', ')}"
          ui.say "  • #{ui.pastel.bold(summary[:variables_count])} variables"
          ui.say "  • #{ui.pastel.bold(summary[:outputs_count])} outputs"
          ui.say "  • Backend: #{summary[:has_backend] ? ui.pastel.green('configured') : ui.pastel.yellow('local')}"
          ui.say "  • Estimated cost: #{ui.pastel.cyan("$#{summary[:estimated_cost]}/month")}"
          
          # Resource breakdown
          if summary[:resource_types].any?
            ui.info "\n🏗️  Resources by type:"
            summary[:resource_types].sort_by { |_, count| -count }.each do |type, count|
              ui.say "  • #{ui.pastel.cyan(type)}: #{count}"
            end
          end
          
          # Key resources details
          display_key_resources(analysis[:resources])
        end
        
        def display_key_resources(resources)
          return if resources.empty?
          
          ui.info "\n🔍 Resource Details:"
          
          resources.each do |resource|
            ui.say "  • #{ui.pastel.bold(resource[:full_name])}"
            
            if resource[:attributes].any?
              resource[:attributes].each do |key, value|
                next if value.nil? || value.to_s.empty?
                formatted_value = format_attribute_value(value)
                ui.say "    #{key}: #{ui.pastel.bright_black(formatted_value)}"
              end
            end
          end
        end
        
        def format_attribute_value(value)
          case value
          when Array
            value.join(', ')
          when Hash
            value.to_json
          when String
            value.length > 50 ? "#{value[0..47]}..." : value
          else
            value.to_s
          end
        end
        
        def display_enhanced_plan_output(plan_result, resource_analysis)
          # Show traditional diff
          @diff.terraform_plan(plan_result[:output])
          
          # Enhanced resource change analysis
          if plan_result[:resource_changes]
            display_detailed_resource_changes(plan_result[:resource_changes], resource_analysis)
          end
          
          # Show impact analysis with enhanced details
          if plan_result[:resource_changes]
            @visualizer.plan_impact({
              create: plan_result[:resource_changes][:create] || [],
              update: plan_result[:resource_changes][:update] || [],
              destroy: plan_result[:resource_changes][:delete] || [],
              details: build_enhanced_change_details(plan_result[:resource_changes], resource_analysis)
            })
          end
        end
        
        def display_detailed_resource_changes(changes, resource_analysis)
          ui.info "\n🔄 Detailed Resource Changes:"
          ui.info "─" * 60
          
          [:create, :update, :delete, :replace].each do |action|
            next unless changes[action] && changes[action].any?
            
            color = case action
                   when :create then :green
                   when :update then :yellow
                   when :delete then :red
                   when :replace then :magenta
                   end
            
            icon = case action
                   when :create then '+'
                   when :update then '~'
                   when :delete then '-'
                   when :replace then '±'
                   end
            
            ui.info "\n#{ui.pastel.decorate("#{icon} #{action.to_s.upcase}:", color)}"
            
            changes[action].each do |resource_ref|
              resource_info = find_resource_info(resource_ref, resource_analysis)
              if resource_info
                ui.say "  • #{ui.pastel.bold(resource_ref)}"
                display_resource_change_details(resource_info, action)
              else
                ui.say "  • #{resource_ref}"
              end
            end
          end
        end
        
        def find_resource_info(resource_ref, resource_analysis)
          return nil unless resource_analysis[:resources]
          
          resource_analysis[:resources].find { |r| r[:full_name] == resource_ref }
        end
        
        def display_resource_change_details(resource_info, action)
          case action
          when :create
            ui.say "    ↳ Creating new #{resource_info[:type]}"
            display_resource_attributes(resource_info[:attributes], "    ")
          when :delete
            ui.say "    ↳ #{ui.pastel.red('⚠️  Will destroy existing resource')}"
            display_resource_attributes(resource_info[:attributes], "    ")
          when :update
            ui.say "    ↳ Modifying existing #{resource_info[:type]}"
          when :replace
            ui.say "    ↳ #{ui.pastel.magenta('⚠️  Will replace (destroy + create)')}"
            display_resource_attributes(resource_info[:attributes], "    ")
          end
        end
        
        def display_resource_attributes(attributes, indent = "")
          return if attributes.empty?
          
          attributes.each do |key, value|
            next if value.nil? || value.to_s.empty?
            formatted_value = format_attribute_value(value)
            ui.say "#{indent}  #{key}: #{ui.pastel.bright_black(formatted_value)}"
          end
        end
        
        def build_enhanced_change_details(changes, resource_analysis)
          details = {}
          
          [:create, :update, :destroy].each do |action|
            next unless changes[action]
            
            details[action] = changes[action].map do |resource_ref|
              resource_info = find_resource_info(resource_ref, resource_analysis)
              if resource_info
                {
                  type: resource_info[:type],
                  name: resource_info[:name],
                  attributes: resource_info[:attributes]
                }
              else
                type, name = resource_ref.split('.', 2)
                { type: type, name: name }
              end
            end
          end
          
          details
        end
        
        def display_current_state(executor, resource_analysis)
          ui.info "\n📈 Current Infrastructure State:"
          ui.info "─" * 60
          
          # Get current state
          state_result = executor.state_list
          
          if state_result[:success] && state_result[:resources]
            ui.info "✅ #{state_result[:resources].count} resources currently managed"
            
            # Group by type
            grouped = state_result[:resources].group_by { |r| r.split('.').first }
            grouped.each do |type, resources|
              ui.say "  • #{ui.pastel.cyan(type)}: #{resources.count} instance(s)"
            end
          else
            ui.info "ℹ️  No existing state found - this will be a fresh deployment"
          end
          
          # Show what would be created on first run
          if resource_analysis[:resources].any?
            ui.info "\n📋 Resources defined in template:"
            resource_analysis[:resources].each do |resource|
              ui.say "  • #{ui.pastel.bright_black(resource[:full_name])}"
            end
          end
        end
        
        def highlight_json_line(line)
          # Basic JSON syntax highlighting
          line
            .gsub(/"([^"]+)":/, ui.pastel.blue("\"\\1\":"))       # Keys
            .gsub(/:\s*"([^"]+)"/, ": #{ui.pastel.green("\"\\1\"")}")  # String values
            .gsub(/:\s*(\d+)/, ": #{ui.pastel.cyan("\\1")}")     # Numbers
            .gsub(/:\s*(true|false)/, ": #{ui.pastel.yellow("\\1")}")  # Booleans
            .gsub(/([{}\[\],])/, ui.pastel.bright_black("\\1"))   # Structural chars
        end
      end
    end
  end
end