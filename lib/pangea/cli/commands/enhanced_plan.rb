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

module Pangea
  module CLI
    module Commands
      # Enhanced Plan command showcasing beautiful UI components
      class EnhancedPlan < BaseCommand
        
        def run(file_path, namespace:, template: nil, show_compiled: false)
          start_time = Time.now
          
          # Display namespace info
          namespace_entity = load_namespace(namespace)
          return unless namespace_entity
          
          ui.namespace_info(namespace_entity)
          puts
          
          # Step 1: Parse and validate templates
          templates = parse_templates_with_progress(file_path, template)
          return if templates.empty?
          
          # Step 2: Compile templates with beautiful progress
          compiled_templates = compile_templates_with_progress(templates)
          
          # Step 3: Generate plan with spinners
          plan_results = generate_plan_with_progress(compiled_templates, namespace_entity)
          
          # Step 4: Display beautiful results
          display_plan_results(plan_results)
          
          # Show performance metrics
          total_duration = Time.now - start_time
          show_performance_metrics(total_duration, compiled_templates, plan_results)
          
          # Celebration!
          ui.celebration("Plan completed successfully! 🎉")
          
        rescue StandardError => e
          banner.error("Plan failed", e.message, [
            "Check your template syntax",
            "Verify namespace configuration", 
            "Run with --debug for more details"
          ])
          exit 1
        end
        
        private
        
        def parse_templates_with_progress(file_path, template_filter)
          spinner = UI::Spinner.file_operation("Parsing #{File.basename(file_path)}")
          
          templates = spinner.spin do
            # Simulate template parsing
            sleep 0.5
            
            all_templates = [
              { name: 'networking', resources: 12 },
              { name: 'compute', resources: 8 },
              { name: 'database', resources: 5 },
              { name: 'monitoring', resources: 15 }
            ]
            
            if template_filter
              all_templates.select { |t| t[:name] == template_filter }
            else
              all_templates
            end
          end
          
          if templates.empty?
            if template_filter
              banner.error("Template not found", "Template '#{template_filter}' not found in #{file_path}", [
                "Available templates: networking, compute, database, monitoring",
                "Remove --template flag to process all templates"
              ])
            else
              banner.error("No templates found", "No valid templates found in #{file_path}", [
                "Check your template syntax",
                "Ensure templates use the template :name do...end syntax"
              ])
            end
            return []
          end
          
          ui.success "Found #{templates.length} template(s)"
          templates
        end
        
        def compile_templates_with_progress(templates)
          ui.section "Template Compilation"
          
          compiled = []
          
          # Use multi-stage spinner for compilation
          UI::Spinner.multi_stage(templates.map { |t| "Compiling #{t[:name]}" }) do |spinner, stage|
            template_name = stage.split(' ').last
            template = templates.find { |t| t[:name] == template_name }
            
            # Simulate compilation time based on resource count
            compilation_time = template[:resources] * 0.1
            sleep compilation_time
            
            compiled << {
              name: template[:name],
              resources: template[:resources],
              status: :compiled,
              duration: compilation_time,
              resource_count: template[:resources]
            }
            
            ui.template_status(template[:name], :compiled, compilation_time)
          end
          
          # Show compilation summary table
          puts "\n"
          puts UI::Table.template_summary(compiled)
          
          compiled
        end
        
        def generate_plan_with_progress(templates, namespace_entity)
          ui.section "Infrastructure Planning"
          
          plan_results = []
          
          templates.each do |template|
            spinner = UI::Spinner.terraform_operation(:plan)
            spinner.update("Planning #{template[:name]} template")
            
            result = spinner.spin do
              # Simulate terraform plan
              sleep 1.5
              
              # Generate realistic plan data
              actions = [:create, :update, :delete, :replace]
              resource_types = ['aws_vpc', 'aws_subnet', 'aws_instance', 'aws_s3_bucket', 'aws_rds_instance']
              
              resources = (1..template[:resources]).map do |i|
                {
                  type: resource_types.sample,
                  name: "resource_#{i}",
                  action: actions.sample,
                  reason: ['Configuration changed', 'New resource', 'Dependency update', 'AMI changed'].sample
                }
              end
              
              {
                template: template[:name],
                resources: resources,
                summary: resources.group_by { |r| r[:action] }.transform_values(&:count)
              }
            end
            
            plan_results << result
          end
          
          plan_results
        end
        
        def display_plan_results(plan_results)
          ui.section "Plan Results"
          
          # Calculate totals
          total_summary = plan_results.reduce({}) do |acc, result|
            result[:summary].each do |action, count|
              acc[action] = (acc[action] || 0) + count
            end
            acc
          end
          
          # Show overall summary banner
          puts banner.operation_summary(:plan, total_summary)
          puts
          
          # Show detailed plan for each template
          plan_results.each do |result|
            ui.say "\n📋 Template: #{ui.pastel.bright_white(result[:template])}"
            puts UI::Table.plan_summary(result[:resources])
          end
          
          # Show cost estimate if available
          show_cost_estimate(plan_results)
        end
        
        def show_cost_estimate(plan_results)
          # Simulate cost estimation
          total_resources = plan_results.sum { |r| r[:resources].length }
          estimated_cost = total_resources * 12.50 # $12.50 per resource estimate
          current_cost = estimated_cost * 0.8 # Assume 80% of estimated for current
          savings = current_cost - estimated_cost
          
          ui.cost_info(
            current: current_cost.round(2),
            estimated: estimated_cost.round(2), 
            savings: savings.round(2)
          )
        end
        
        def show_performance_metrics(total_duration, templates, plan_results)
          compilation_time = templates.sum { |t| t[:duration] || 0 }
          planning_time = total_duration - compilation_time
          
          metrics = {
            compilation_time: "#{compilation_time.round(1)}s",
            planning_time: "#{planning_time.round(1)}s",
            memory_usage: "#{rand(50..200)}MB",
            terraform_version: "1.6.4"
          }
          
          ui.performance_info(metrics)
        end
      end
    end
  end
end