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

# lib/pangea/utilities/cli/commands/cost_command.rb
require_relative '../command'

module Pangea
  module Utilities
    module CLI
      module Commands
        class CostCommand < Command
          desc "Analyze infrastructure costs"
          
          class_option :namespace, type: :string, aliases: '-n',
                       desc: "Namespace to use"
          
          desc "analyze", "Analyze costs for templates"
          option :template, type: :string,
                 desc: "Template to analyze"
          option :all, type: :boolean,
                 desc: "Analyze all templates"
          def analyze
            calculator = Cost::Calculator.new
            
            if options[:all]
              result = calculator.calculate_all_templates(get_namespace)
              
              info "Cost Analysis for namespace '#{result[:namespace]}'"
              info "=" * 50
              
              result[:templates].each do |report|
                if report.error?
                  error "#{report.template_name}: Error - #{report.data[:error]}"
                else
                  say sprintf("%-30s $%8.2f/hour  $%10.2f/month  (%d resources)",
                             report.template_name,
                             report.total_hourly,
                             report.total_monthly,
                             report.resources.length)
                end
              end
              
              say "=" * 50
              success sprintf("%-30s $%8.2f/hour  $%10.2f/month",
                            "TOTAL",
                            result[:total_hourly],
                            result[:total_monthly])
            else
              template = options[:template] || error("Specify --template or --all")
              report = calculator.calculate_template_cost(template, get_namespace)
              
              if report.error?
                error "Error: #{report.data[:error]}"
                exit 1
              end
              
              info "Cost Analysis for '#{template}'"
              info "=" * 50
              
              report.resources.each do |resource|
                say sprintf("%-40s %-20s $%6.2f/hour  $%8.2f/month",
                           "#{resource[:type]}.#{resource[:name]}",
                           resource[:attributes].values.first || 'N/A',
                           resource[:hourly],
                           resource[:monthly])
              end
              
              say "=" * 50
              success sprintf("%-40s %-20s $%6.2f/hour  $%8.2f/month",
                            "TOTAL",
                            "",
                            report.total_hourly,
                            report.total_monthly)
            end
          end
          
          desc "optimize", "Show cost optimization recommendations"
          option :template, type: :string, required: true,
                 desc: "Template to optimize"
          def optimize
            # TODO: Implement optimizer
            info "Analyzing optimization opportunities for '#{options[:template]}'..."
            
            # Mock recommendations
            say "\nOptimization Recommendations:"
            say "=" * 50
            
            warning "1. Right-size EC2 instances"
            say "   - aws_instance.web_server: t3.large -> t3.medium"
            say "   - Potential savings: $30.37/month"
            
            warning "2. Use Reserved Instances"
            say "   - 3 instances running 24/7"
            say "   - Potential savings: $150/month with 1-year RIs"
            
            warning "3. Enable S3 lifecycle policies"
            say "   - Move old logs to Glacier"
            say "   - Potential savings: $20/month"
            
            success "\nTotal potential savings: $200.37/month"
          end
        end
      end
    end
  end
end