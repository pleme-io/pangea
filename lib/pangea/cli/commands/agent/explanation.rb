# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      module Agent
        # Infrastructure explanation
        module Explanation
          def explain_infrastructure(file, template: nil, namespace: nil)
            return { error: 'File required' } unless file

            analysis = analyze_infrastructure(file, template: template, namespace: namespace)

            {
              summary: 'Infrastructure configuration using Pangea',
              templates: analysis[:templates].map do |t|
                {
                  name: t[:name],
                  purpose: infer_template_purpose(t),
                  resources: t[:resources].group_by { |r| r[:type] }.transform_values(&:count),
                  description: generate_template_description(t)
                }
              end,
              overall_architecture: infer_architecture_pattern(analysis)
            }
          end

          def diff_infrastructure(_file, template: nil, namespace: nil)
            {
              notice: 'Diff requires terraform plan execution',
              hint: "Use 'pangea plan #{_file}' with appropriate flags"
            }
          end

          private

          def infer_template_purpose(template)
            name = template[:name].to_s
            resources = template[:resources]

            if name.include?('network') || resources.any? { |r| r[:terraform_type] == 'aws_vpc' }
              'Network infrastructure'
            elsif name.include?('compute') || resources.any? { |r| r[:terraform_type] == 'aws_instance' }
              'Compute resources'
            elsif name.include?('database') || resources.any? { |r| r[:terraform_type] =~ /aws_(db|rds)/ }
              'Database infrastructure'
            elsif name.include?('security')
              'Security configuration'
            else
              'Infrastructure resources'
            end
          end

          def generate_template_description(template)
            resources = template[:resources]
            resource_types = resources.map { |r| r[:terraform_type] || r[:resource_type] }.uniq

            "This template defines #{resources.count} resources including #{resource_types.join(', ')}. " \
              "It has #{template[:metrics][:output_count]} outputs and " \
              "#{template[:dependencies][:internal_refs].count} internal dependencies."
          end

          def infer_architecture_pattern(analysis)
            has_vpc = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] == 'aws_vpc' } }
            has_ec2 = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] == 'aws_instance' } }
            has_rds = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] =~ /aws_db_instance/ } }
            has_alb = analysis[:templates].any? { |t| t[:resources].any? { |r| r[:terraform_type] == 'aws_lb' } }

            if has_vpc && has_ec2 && has_rds && has_alb
              'Three-tier web application architecture'
            elsif has_vpc && has_ec2
              'Basic compute infrastructure'
            elsif has_rds
              'Database-focused infrastructure'
            else
              'Custom infrastructure pattern'
            end
          end
        end
      end
    end
  end
end
