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
require 'pangea/cli/commands/base_command'
require 'pangea/cli/commands/inspect'
require 'pangea/cli/commands/plan'
require 'pangea/cli/commands/apply'
require 'pangea/compilation/template_compiler'
require 'pangea/execution/terraform_executor'

module Pangea
  module CLI
    module Commands
      # Agent command for AI/automation-friendly operations
      class Agent < BaseCommand
        def run(action, target = nil, **options)
          response = case action
          when 'analyze'
            analyze_infrastructure(target, **options)
          when 'validate'
            validate_infrastructure(target, **options)
          when 'diff'
            diff_infrastructure(target, **options)
          when 'cost'
            estimate_cost(target, **options)
          when 'security'
            security_scan(target, **options)
          when 'dependencies'
            analyze_dependencies(target, **options)
          when 'suggest'
            suggest_improvements(target, **options)
          when 'explain'
            explain_infrastructure(target, **options)
          else
            { 
              error: "Unknown agent action: #{action}",
              available_actions: %w[analyze validate diff cost security dependencies suggest explain]
            }
          end
          
          # Always output JSON for agents
          puts JSON.pretty_generate({
            action: action,
            target: target,
            options: options,
            timestamp: Time.now.iso8601,
            response: response
          })
        rescue StandardError => e
          puts JSON.pretty_generate({
            action: action,
            target: target,
            error: e.message,
            error_class: e.class.name,
            backtrace: e.backtrace.first(5)
          })
        end
        
        private
        
        def analyze_infrastructure(file, template: nil, namespace: nil)
          return { error: "File required" } unless file
          return { error: "File not found: #{file}" } unless File.exist?(file)
          
          compiler = Compilation::TemplateCompiler.new
          templates = compiler.extract_templates(file)
          
          analysis = {
            file: file,
            templates: templates.map { |t| analyze_template_deep(t, file) },
            statistics: calculate_statistics(templates),
            complexity: assess_complexity(templates),
            best_practices: check_best_practices(templates)
          }
          
          if template
            analysis[:templates] = analysis[:templates].select { |t| t[:name].to_s == template.to_s }
          end
          
          analysis
        end
        
        def analyze_template_deep(template, file)
          content = template[:content]
          
          {
            name: template[:name],
            metrics: {
              lines_of_code: content.lines.count,
              resource_count: content.scan(/resource\s+:/).count,
              resource_function_count: content.scan(/aws_\w+\s*\(/).count,
              data_source_count: content.scan(/data\s+:/).count,
              output_count: content.scan(/output\s+:/).count,
              local_count: content.scan(/locals\s+do/).count,
              provider_count: content.scan(/provider\s+:/).count
            },
            resources: extract_detailed_resources(content),
            dependencies: extract_dependencies(content),
            potential_issues: detect_potential_issues(content)
          }
        end
        
        def extract_detailed_resources(content)
          resources = []
          
          # Extract traditional resources
          content.scan(/resource\s+:(\w+),\s*:(\w+)\s+do(.*?)end/m) do |type, name, block|
            resources << {
              type: "resource",
              terraform_type: type,
              name: name,
              has_count: block.include?('count'),
              has_for_each: block.include?('for_each'),
              has_lifecycle: block.include?('lifecycle'),
              has_depends_on: block.include?('depends_on')
            }
          end
          
          # Extract resource functions
          content.scan(/(aws_\w+)\s*\(\s*:(\w+),\s*(\{[^}]*\})/) do |func, name, args|
            resources << {
              type: "resource_function",
              function: func,
              name: name,
              resource_type: func.sub('aws_', ''),
              arguments_preview: args[0..100] + (args.length > 100 ? '...' : '')
            }
          end
          
          resources
        end
        
        def extract_dependencies(content)
          deps = {
            internal_refs: [],
            data_refs: [],
            module_refs: [],
            remote_state_refs: []
          }
          
          # Internal resource references
          content.scan(/ref\(:(\w+),\s*:(\w+),\s*:(\w+)\)/) do |type, name, attr|
            deps[:internal_refs] << { type: type, name: name, attribute: attr }
          end
          
          # Data source references
          content.scan(/data\.(\w+)\.(\w+)\.(\w+)/) do |type, name, attr|
            deps[:data_refs] << { type: type, name: name, attribute: attr }
          end
          
          # Module references
          content.scan(/module\.(\w+)\.(\w+)/) do |name, output|
            deps[:module_refs] << { module: name, output: output }
          end
          
          # Remote state references
          content.scan(/remote_state\(:(\w+)\)/) do |name|
            deps[:remote_state_refs] << { name: name[0] }
          end
          
          deps
        end
        
        def detect_potential_issues(content)
          issues = []
          
          # Hard-coded values that should be variables
          content.scan(/["'](\d+\.\d+\.\d+\.\d+\/\d+)["']/) do |cidr|
            issues << {
              type: "hard_coded_cidr",
              value: cidr[0],
              suggestion: "Consider using a variable for CIDR blocks"
            }
          end
          
          # Hard-coded AMI IDs
          content.scan(/ami-[a-f0-9]{17}/) do |ami|
            issues << {
              type: "hard_coded_ami",
              value: ami,
              suggestion: "Use data source to look up AMI dynamically"
            }
          end
          
          # Missing tags
          if content.include?('aws_instance') && !content.include?('tags')
            issues << {
              type: "missing_tags",
              resource: "aws_instance",
              suggestion: "Add tags for cost allocation and management"
            }
          end
          
          # Large instance types in dev
          if content.match(/instance_type\s*[=:]\s*["']([xmc]\d+\.(?:2xlarge|4xlarge|8xlarge))/)
            issues << {
              type: "large_instance_type",
              value: $1,
              suggestion: "Consider smaller instance types for non-production"
            }
          end
          
          issues
        end
        
        def calculate_statistics(templates)
          total_resources = 0
          total_lines = 0
          resource_types = Hash.new(0)
          
          templates.each do |t|
            content = t[:content]
            total_lines += content.lines.count
            
            content.scan(/resource\s+:(\w+)/) { |type| resource_types[type[0]] += 1 }
            content.scan(/(aws_\w+)\s*\(/) { |func| resource_types[func[0]] += 1 }
            total_resources += content.scan(/resource\s+:/).count + content.scan(/aws_\w+\s*\(/).count
          end
          
          {
            template_count: templates.size,
            total_resources: total_resources,
            total_lines: total_lines,
            average_resources_per_template: templates.empty? ? 0 : (total_resources.to_f / templates.size).round(2),
            resource_types: resource_types.sort_by { |_, count| -count }.to_h,
            most_used_resource: resource_types.max_by { |_, count| count }&.first
          }
        end
        
        def assess_complexity(templates)
          complexity_scores = templates.map do |t|
            content = t[:content]
            score = 0
            
            # Base complexity from resource count
            score += content.scan(/resource\s+:/).count * 2
            score += content.scan(/aws_\w+\s*\(/).count * 1.5
            
            # Additional complexity factors
            score += content.scan(/count\s*=/).count * 3
            score += content.scan(/for_each\s*=/).count * 4
            score += content.scan(/dynamic\s+"/).count * 5
            score += content.scan(/locals\s+do/).count * 2
            score += content.scan(/module\s+:/).count * 3
            
            { template: t[:name], score: score }
          end
          
          total_score = complexity_scores.sum { |c| c[:score] }
          
          {
            total_score: total_score,
            average_score: templates.empty? ? 0 : (total_score.to_f / templates.size).round(2),
            rating: complexity_rating(total_score),
            by_template: complexity_scores,
            recommendations: complexity_recommendations(total_score)
          }
        end
        
        def complexity_rating(score)
          case score
          when 0..20 then "simple"
          when 21..50 then "moderate"
          when 51..100 then "complex"
          else "very_complex"
          end
        end
        
        def complexity_recommendations(score)
          recommendations = []
          
          if score > 50
            recommendations << "Consider breaking down into smaller templates"
            recommendations << "Use modules to encapsulate repeated patterns"
          end
          
          if score > 100
            recommendations << "Infrastructure is very complex - consider using architecture patterns"
            recommendations << "Document dependencies and relationships clearly"
          end
          
          recommendations
        end
        
        def check_best_practices(templates)
          practices = {
            followed: [],
            violations: []
          }
          
          templates.each do |t|
            content = t[:content]
            
            # Good practices
            if content.include?('tags') || content.include?('tags:')
              practices[:followed] << "Resource tagging implemented in #{t[:name]}"
            end
            
            if content.match(/aws_\w+\s*\(/)
              practices[:followed] << "Using type-safe resource functions in #{t[:name]}"
            end
            
            # Violations
            if content.match(/provider\s+:\w+\s+do.*region\s+["'][\w-]+["']/m)
              practices[:violations] << "Hard-coded provider region in #{t[:name]}"
            end
            
            if content.scan(/resource\s+:/).count > 50
              practices[:violations] << "Template #{t[:name]} has too many resources (>50)"
            end
          end
          
          practices
        end
        
        def validate_infrastructure(file, template: nil, namespace: nil)
          return { error: "File required" } unless file
          
          compiler = Compilation::TemplateCompiler.new
          results = compiler.compile_file(file, namespace: namespace, template: template)
          
          validation_results = results.map do |result|
            if result[:success]
              {
                template: result[:name],
                valid: true,
                terraform_json: JSON.parse(result[:json])
              }
            else
              {
                template: result[:name],
                valid: false,
                error: result[:error]
              }
            end
          end
          
          {
            all_valid: validation_results.all? { |r| r[:valid] },
            results: validation_results
          }
        end
        
        def diff_infrastructure(file, template: nil, namespace: nil)
          # This would integrate with terraform plan to show differences
          {
            notice: "Diff requires terraform plan execution",
            hint: "Use 'pangea plan #{file}' with appropriate flags"
          }
        end
        
        def estimate_cost(file, template: nil, namespace: nil)
          return { error: "File required" } unless file
          
          # Basic cost estimation based on resource types
          compiler = Compilation::TemplateCompiler.new
          templates = compiler.extract_templates(file)
          
          cost_estimates = templates.map do |t|
            content = t[:content]
            estimate = estimate_template_cost(content)
            
            {
              template: t[:name],
              estimated_monthly_cost: estimate[:total],
              breakdown: estimate[:breakdown]
            }
          end
          
          total = cost_estimates.sum { |e| e[:estimated_monthly_cost] }
          
          {
            total_estimated_monthly_cost: total,
            by_template: cost_estimates,
            disclaimer: "These are rough estimates. Use AWS Cost Calculator for accurate pricing."
          }
        end
        
        def estimate_template_cost(content)
          breakdown = {}
          total = 0.0
          
          # Very rough estimates for common resources
          if content.match(/aws_instance.*instance_type\s*[=:]\s*["']t3\.micro/)
            breakdown[:ec2_t3_micro] = 8.50
            total += 8.50
          end
          
          if content.match(/aws_db_instance.*instance_class\s*[=:]\s*["']db\.t3\.micro/)
            breakdown[:rds_t3_micro] = 15.00
            total += 15.00
          end
          
          if content.include?('aws_lb') || content.include?('aws_alb')
            breakdown[:load_balancer] = 25.00
            total += 25.00
          end
          
          if content.include?('aws_nat_gateway')
            breakdown[:nat_gateway] = 45.00
            total += 45.00
          end
          
          { total: total, breakdown: breakdown }
        end
        
        def security_scan(file, template: nil, namespace: nil)
          return { error: "File required" } unless file
          
          compiler = Compilation::TemplateCompiler.new
          templates = compiler.extract_templates(file)
          
          security_issues = []
          
          templates.each do |t|
            content = t[:content]
            
            # Check for common security issues
            if content.match(/ingress.*from_port\s*[=:]\s*0.*to_port\s*[=:]\s*65535/m)
              security_issues << {
                template: t[:name],
                severity: "high",
                issue: "Security group allows all ports",
                recommendation: "Restrict to specific required ports"
              }
            end
            
            if content.match(/cidr_blocks\s*[=:]\s*\[?\s*["']0\.0\.0\.0\/0/)
              security_issues << {
                template: t[:name],
                severity: "medium",
                issue: "Security group allows traffic from anywhere",
                recommendation: "Restrict to known IP ranges"
              }
            end
            
            if content.include?('aws_s3_bucket') && !content.include?('encryption')
              security_issues << {
                template: t[:name],
                severity: "medium",
                issue: "S3 bucket without encryption",
                recommendation: "Enable server-side encryption"
              }
            end
          end
          
          {
            issues_found: security_issues.count,
            issues: security_issues,
            summary: {
              high: security_issues.count { |i| i[:severity] == "high" },
              medium: security_issues.count { |i| i[:severity] == "medium" },
              low: security_issues.count { |i| i[:severity] == "low" }
            }
          }
        end
        
        def analyze_dependencies(file, template: nil, namespace: nil)
          return { error: "File required" } unless file
          
          compiler = Compilation::TemplateCompiler.new
          templates = compiler.extract_templates(file)
          
          all_deps = {
            internal: {},
            external: {},
            graph: []
          }
          
          templates.each do |t|
            deps = extract_dependencies(t[:content])
            
            # Build dependency graph
            deps[:internal_refs].each do |ref|
              all_deps[:graph] << {
                from: t[:name],
                to: ref[:name],
                type: "resource_ref",
                attribute: ref[:attribute]
              }
            end
            
            all_deps[:internal][t[:name]] = deps
          end
          
          all_deps
        end
        
        def suggest_improvements(file, template: nil, namespace: nil)
          analysis = analyze_infrastructure(file, template: template, namespace: namespace)
          
          suggestions = []
          
          # Based on analysis, provide suggestions
          if analysis[:complexity][:rating] == "very_complex"
            suggestions << {
              category: "architecture",
              suggestion: "Consider using Pangea architecture patterns to simplify",
              priority: "high"
            }
          end
          
          analysis[:templates].each do |t|
            if t[:metrics][:resource_count] > 30
              suggestions << {
                category: "organization",
                template: t[:name],
                suggestion: "Split template into smaller, focused templates",
                priority: "medium"
              }
            end
            
            if t[:potential_issues].any? { |i| i[:type] == "hard_coded_ami" }
              suggestions << {
                category: "maintainability",
                template: t[:name],
                suggestion: "Use data sources for AMI lookups",
                priority: "medium"
              }
            end
          end
          
          suggestions
        end
        
        def explain_infrastructure(file, template: nil, namespace: nil)
          return { error: "File required" } unless file
          
          analysis = analyze_infrastructure(file, template: template, namespace: namespace)
          
          explanation = {
            summary: "Infrastructure configuration using Pangea",
            templates: analysis[:templates].map do |t|
              {
                name: t[:name],
                purpose: infer_template_purpose(t),
                resources: t[:resources].group_by { |r| r[:type] }
                                      .transform_values(&:count),
                description: generate_template_description(t)
              }
            end,
            overall_architecture: infer_architecture_pattern(analysis)
          }
          
          explanation
        end
        
        def infer_template_purpose(template)
          name = template[:name].to_s
          resources = template[:resources]
          
          case
          when name.include?('network') || resources.any? { |r| r[:terraform_type] == 'aws_vpc' }
            "Network infrastructure"
          when name.include?('compute') || resources.any? { |r| r[:terraform_type] == 'aws_instance' }
            "Compute resources"
          when name.include?('database') || resources.any? { |r| r[:terraform_type] =~ /aws_(db|rds)/ }
            "Database infrastructure"
          when name.include?('security')
            "Security configuration"
          else
            "Infrastructure resources"
          end
        end
        
        def generate_template_description(template)
          resources = template[:resources]
          resource_types = resources.map { |r| r[:terraform_type] || r[:resource_type] }.uniq
          
          "This template defines #{resources.count} resources including #{resource_types.join(', ')}. " +
          "It has #{template[:metrics][:output_count]} outputs and " +
          "#{template[:dependencies][:internal_refs].count} internal dependencies."
        end
        
        def infer_architecture_pattern(analysis)
          # Try to identify common patterns
          has_vpc = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] == 'aws_vpc' } }
          has_ec2 = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] == 'aws_instance' } }
          has_rds = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] =~ /aws_db_instance/ } }
          has_alb = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] == 'aws_lb' } }
          
          if has_vpc && has_ec2 && has_rds && has_alb
            "Three-tier web application architecture"
          elsif has_vpc && has_ec2
            "Basic compute infrastructure"
          elsif has_rds
            "Database-focused infrastructure"
          else
            "Custom infrastructure pattern"
          end
        end
      end
    end
  end
end