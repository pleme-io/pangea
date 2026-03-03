# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      # Improvement suggestions for Agent command
      module AgentSuggestions
          def suggest_improvements(file, template: nil, namespace: nil)
            analysis = analyze_infrastructure(file, template: template, namespace: namespace)
            suggestions = []

            if analysis[:complexity][:rating] == 'very_complex'
              suggestions << {
                category: 'architecture',
                suggestion: 'Consider using Pangea architecture patterns to simplify',
                priority: 'high'
              }
            end

            analysis[:templates].each do |t|
              suggestions.concat(template_suggestions(t))
            end

            suggestions
          end

          private

          def template_suggestions(template)
            suggestions = []

            if template[:metrics][:resource_count] > 30
              suggestions << {
                category: 'organization',
                template: template[:name],
                suggestion: 'Split template into smaller, focused templates',
                priority: 'medium'
              }
            end

            if template[:potential_issues].any? { |i| i[:type] == 'hard_coded_ami' }
              suggestions << {
                category: 'maintainability',
                template: template[:name],
                suggestion: 'Use data sources for AMI lookups',
                priority: 'medium'
              }
            end

            suggestions
          end
        end
      end
    end
  end
