# frozen_string_literal: true

require 'json'

module Pangea
  module CLI
    module Commands
      module Agent
        # Validation and best practices
        module Validation
          def validate_infrastructure(file, template: nil, namespace: nil)
            return { error: 'File required' } unless file

            compiler = Compilation::TemplateCompiler.new
            results = compiler.compile_file(file, namespace: namespace, template: template)

            validation_results = results.map do |result|
              if result[:success]
                { template: result[:name], valid: true, terraform_json: JSON.parse(result[:json]) }
              else
                { template: result[:name], valid: false, error: result[:error] }
              end
            end

            { all_valid: validation_results.all? { |r| r[:valid] }, results: validation_results }
          end

          def check_best_practices(templates)
            practices = { followed: [], violations: [] }

            templates.each do |t|
              content = t[:content]

              if content.include?('tags') || content.include?('tags:')
                practices[:followed] << "Resource tagging implemented in #{t[:name]}"
              end

              if content.match(/aws_\w+\s*\(/)
                practices[:followed] << "Using type-safe resource functions in #{t[:name]}"
              end

              if content.match(/provider\s+:\w+\s+do.*region\s+["'][\w-]+["']/m)
                practices[:violations] << "Hard-coded provider region in #{t[:name]}"
              end

              if content.scan(/resource\s+:/).count > 50
                practices[:violations] << "Template #{t[:name]} has too many resources (>50)"
              end
            end

            practices
          end

          def detect_potential_issues(content)
            issues = []

            content.scan(/["'](\d+\.\d+\.\d+\.\d+\/\d+)["']/) do |cidr|
              issues << { type: 'hard_coded_cidr', value: cidr[0], suggestion: 'Consider using a variable for CIDR blocks' }
            end

            content.scan(/ami-[a-f0-9]{17}/) do |ami|
              issues << { type: 'hard_coded_ami', value: ami, suggestion: 'Use data source to look up AMI dynamically' }
            end

            if content.include?('aws_instance') && !content.include?('tags')
              issues << { type: 'missing_tags', resource: 'aws_instance', suggestion: 'Add tags for cost allocation and management' }
            end

            if content.match(/instance_type\s*[=:]\s*["']([xmc]\d+\.(?:2xlarge|4xlarge|8xlarge))/)
              issues << { type: 'large_instance_type', value: $1, suggestion: 'Consider smaller instance types for non-production' }
            end

            issues
          end
        end
      end
    end
  end
end
