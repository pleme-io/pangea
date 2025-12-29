# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      module Agent
        # Template analysis operations
        module Analysis
          def analyze_infrastructure(file, template: nil, namespace: nil)
            return { error: 'File required' } unless file
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

            analysis[:templates] = analysis[:templates].select { |t| t[:name].to_s == template.to_s } if template
            analysis
          end

          def analyze_template_deep(template, _file)
            content = template[:content]

            {
              name: template[:name],
              metrics: extract_metrics(content),
              resources: extract_detailed_resources(content),
              dependencies: extract_dependencies(content),
              potential_issues: detect_potential_issues(content)
            }
          end

          private

          def extract_metrics(content)
            {
              lines_of_code: content.lines.count,
              resource_count: content.scan(/resource\s+:/).count,
              resource_function_count: content.scan(/aws_\w+\s*\(/).count,
              data_source_count: content.scan(/data\s+:/).count,
              output_count: content.scan(/output\s+:/).count,
              local_count: content.scan(/locals\s+do/).count,
              provider_count: content.scan(/provider\s+:/).count
            }
          end

          def extract_detailed_resources(content)
            resources = []

            content.scan(/resource\s+:(\w+),\s*:(\w+)\s+do(.*?)end/m) do |type, name, block|
              resources << {
                type: 'resource',
                terraform_type: type,
                name: name,
                has_count: block.include?('count'),
                has_for_each: block.include?('for_each'),
                has_lifecycle: block.include?('lifecycle'),
                has_depends_on: block.include?('depends_on')
              }
            end

            content.scan(/(aws_\w+)\s*\(\s*:(\w+),\s*(\{[^}]*\})/) do |func, name, args|
              resources << {
                type: 'resource_function',
                function: func,
                name: name,
                resource_type: func.sub('aws_', ''),
                arguments_preview: args[0..100] + (args.length > 100 ? '...' : '')
              }
            end

            resources
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
        end
      end
    end
  end
end
