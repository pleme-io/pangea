# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      module Agent
        # Cost estimation
        module Cost
          def estimate_cost(file, template: nil, namespace: nil)
            return { error: 'File required' } unless file

            compiler = Compilation::TemplateCompiler.new
            templates = compiler.extract_templates(file)

            cost_estimates = templates.map do |t|
              estimate = estimate_template_cost(t[:content])
              { template: t[:name], estimated_monthly_cost: estimate[:total], breakdown: estimate[:breakdown] }
            end

            total = cost_estimates.sum { |e| e[:estimated_monthly_cost] }

            {
              total_estimated_monthly_cost: total,
              by_template: cost_estimates,
              disclaimer: 'These are rough estimates. Use AWS Cost Calculator for accurate pricing.'
            }
          end

          private

          def estimate_template_cost(content)
            breakdown = {}
            total = 0.0

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
        end
      end
    end
  end
end
