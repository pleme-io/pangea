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

require 'tty-box'
require 'pastel'

module Pangea
  module CLI
    module UI
      class Banner
        # Renders operation summary boxes for plan, apply, and destroy operations
        class OperationSummary
          def initialize(pastel = Pastel.new)
            @pastel = pastel
          end

          def render(operation, stats)
            case operation
            when :plan
              plan_summary(stats)
            when :apply
              apply_summary(stats)
            when :destroy
              destroy_summary(stats)
            end
          end

          private

          def plan_summary(stats)
            created = stats[:create] || 0
            updated = stats[:update] || 0
            deleted = stats[:delete] || 0
            replaced = stats[:replace] || 0

            content = build_plan_content(created, updated, deleted, replaced)

            build_box(content, color: :blue, width: 40)
          end

          def build_plan_content(created, updated, deleted, replaced)
            total_changes = created + updated + deleted + replaced
            return no_changes_content if total_changes.zero?

            content = @pastel.bright_blue("Plan Summary") + "\n\n"
            content += "#{@pastel.green('+')} #{created} to create\n" if created.positive?
            content += "#{@pastel.yellow('~')} #{updated} to update\n" if updated.positive?
            content += "#{@pastel.red('-')} #{deleted} to delete\n" if deleted.positive?
            content += "#{@pastel.magenta('+-')} #{replaced} to replace\n" if replaced.positive?
            content
          end

          def no_changes_content
            content = @pastel.bright_green("No changes required") + "\n\n"
            content + @pastel.bright_black("Your infrastructure matches the desired state")
          end

          def apply_summary(stats)
            total_resources = stats[:total] || 0
            duration = stats[:duration] || 0
            cost_estimate = stats[:estimated_cost]

            content = @pastel.bright_green("Apply Complete") + "\n\n"
            content += "#{@pastel.white('Resources')}: #{@pastel.bright_white(total_resources)}\n"
            content += "#{@pastel.white('Duration')}: #{@pastel.bright_white(format_duration(duration))}\n"

            if cost_estimate
              content += "#{@pastel.white('Est. Cost')}: #{@pastel.bright_white("$#{cost_estimate}/month")}\n"
            end

            build_box(content, color: :green, width: 45)
          end

          def destroy_summary(stats)
            destroyed = stats[:destroyed] || 0
            duration = stats[:duration] || 0

            content = @pastel.bright_red("Destroy Complete") + "\n\n"
            content += "#{@pastel.white('Destroyed')}: #{@pastel.bright_white(destroyed)} resources\n"
            content += "#{@pastel.white('Duration')}: #{@pastel.bright_white(format_duration(duration))}\n"

            build_box(content, color: :red, width: 45)
          end

          def build_box(content, color:, width:)
            TTY::Box.frame(
              content.strip,
              width: width,
              align: :left,
              border: :light,
              style: { border: { color: color } }
            )
          end

          def format_duration(seconds)
            if seconds < 60
              "#{seconds.round(1)}s"
            else
              minutes = (seconds / 60).floor
              remaining_seconds = (seconds % 60).round
              "#{minutes}m #{remaining_seconds}s"
            end
          end
        end
      end
    end
  end
end
