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

module Pangea
  module CLI
    module UI
      class Logger
        # Info panel display methods for the Logger
        module InfoPanels
          # Cost information display
          def cost_info(current: nil, estimated: nil, savings: nil)
            return unless current || estimated || savings

            content = build_content do |c|
              c << "#{@pastel.white('Current')}: #{@pastel.bright_white("$#{current}/month")}" if current
              c << "#{@pastel.white('Estimated')}: #{@pastel.bright_white("$#{estimated}/month")}" if estimated

              if savings && savings != 0
                color = savings > 0 ? :bright_green : :bright_red
                symbol = savings > 0 ? "+" : "-"
                c << "#{symbol} #{@pastel.white('Savings')}: #{@pastel.decorate("$#{savings.abs}/month", color)}"
              end
            end

            display_box(content, title: "Cost Impact", color: :yellow, width: 40)
          end

          # Time and performance metrics
          def performance_info(metrics)
            metric_labels = {
              compilation_time: 'Compilation',
              planning_time:    'Planning',
              apply_time:       'Apply',
              memory_usage:     'Memory',
              terraform_version: 'Terraform'
            }

            content = build_content do |c|
              metric_labels.each do |key, label|
                c << "#{@pastel.white(label)}: #{@pastel.bright_white(metrics[key])}" if metrics[key]
              end
            end

            return if content.empty?
            display_box(content, title: "Performance", color: :blue, width: 50)
          end

          # Namespace information display
          def namespace_info(namespace_entity)
            content = build_content do |c|
              c << "#{@pastel.white('Name')}: #{@pastel.bright_white(namespace_entity.name)}"
              c << "#{@pastel.white('Backend')}: #{@pastel.bright_white(namespace_entity.state.type)}"

              case namespace_entity.state.type
              when 's3'
                c << "#{@pastel.white('Bucket')}: #{@pastel.cyan(namespace_entity.state.bucket)}"
                c << "#{@pastel.white('Region')}: #{@pastel.cyan(namespace_entity.state.region)}"
              when 'local'
                c << "#{@pastel.white('Path')}: #{@pastel.cyan(namespace_entity.state.path)}"
              end

              if namespace_entity.description
                c << "#{@pastel.white('Description')}: #{@pastel.bright_black(namespace_entity.description)}"
              end
            end

            display_box(content, title: "Namespace", color: :cyan, width: 60)
          end

          # Warning panel for important notices
          def warning_panel(title, warnings)
            content = @pastel.bright_yellow("! #{title}") + "\n\n"
            content += warnings.map { |w| "#{@pastel.yellow('*')} #{@pastel.white(w)}" }.join("\n")

            display_box(content, color: :yellow, width: 70, border: :thick)
          end

          # Command completion celebration
          def celebration(message, emoji = "*")
            say "\n#{emoji} #{@pastel.bright_green(message)} #{emoji}", color: :bright_green
            say @pastel.bright_black("-" * (message.length + 6))
          end
        end
      end
    end
  end
end
