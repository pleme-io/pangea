# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      # Complexity assessment for Agent command
      module AgentComplexity
          def assess_complexity(templates)
            complexity_scores = templates.map do |t|
              content = t[:content]
              score = calculate_template_complexity(content)
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

          private

          def calculate_template_complexity(content)
            score = 0
            score += content.scan(/resource\s+:/).count * 2
            score += content.scan(/aws_\w+\s*\(/).count * 1.5
            score += content.scan(/count\s*=/).count * 3
            score += content.scan(/for_each\s*=/).count * 4
            score += content.scan(/dynamic\s+"/).count * 5
            score += content.scan(/locals\s+do/).count * 2
            score += content.scan(/module\s+:/).count * 3
            score
          end

          def complexity_rating(score)
            case score
            when 0..20 then 'simple'
            when 21..50 then 'moderate'
            when 51..100 then 'complex'
            else 'very_complex'
            end
          end

          def complexity_recommendations(score)
            recommendations = []

            if score > 50
              recommendations << 'Consider breaking down into smaller templates'
              recommendations << 'Use modules to encapsulate repeated patterns'
            end

            if score > 100
              recommendations << 'Infrastructure is very complex - consider using architecture patterns'
              recommendations << 'Document dependencies and relationships clearly'
            end

            recommendations
          end
        end
      end
    end
  end
