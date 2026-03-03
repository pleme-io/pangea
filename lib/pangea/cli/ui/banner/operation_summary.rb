# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-box'

module Pangea
  module CLI
    module UI
      class Banner
        # Renders operation summary boxes for plan, apply, and destroy operations
        class OperationSummary
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

            build_box(content, color: :info, width: 40)
          end

          def build_plan_content(created, updated, deleted, replaced)
            total_changes = created + updated + deleted + replaced
            return no_changes_content if total_changes.zero?

            content = Boreal.paint("Plan Summary", :info) + "\n\n"
            content += "#{Boreal.paint('+', :create)} #{created} to create\n" if created.positive?
            content += "#{Boreal.paint('~', :update)} #{updated} to update\n" if updated.positive?
            content += "#{Boreal.paint('-', :delete)} #{deleted} to delete\n" if deleted.positive?
            content += "#{Boreal.paint('+-', :replace)} #{replaced} to replace\n" if replaced.positive?
            content
          end

          def no_changes_content
            content = Boreal.paint("No changes required", :success) + "\n\n"
            content + Boreal.paint("Your infrastructure matches the desired state", :muted)
          end

          def apply_summary(stats)
            total_resources = stats[:total] || 0
            duration = stats[:duration] || 0
            cost_estimate = stats[:estimated_cost]

            content = Boreal.paint("Apply Complete", :success) + "\n\n"
            content += "#{Boreal.paint('Resources', :text)}: #{Boreal.paint(total_resources, :bright)}\n"
            content += "#{Boreal.paint('Duration', :text)}: #{Boreal.paint(format_duration(duration), :bright)}\n"

            if cost_estimate
              content += "#{Boreal.paint('Est. Cost', :text)}: #{Boreal.paint("$#{cost_estimate}/month", :bright)}\n"
            end

            build_box(content, color: :success, width: 45)
          end

          def destroy_summary(stats)
            destroyed = stats[:destroyed] || 0
            duration = stats[:duration] || 0

            content = Boreal.paint("Destroy Complete", :error) + "\n\n"
            content += "#{Boreal.paint('Destroyed', :text)}: #{Boreal.paint("#{destroyed} resources", :bright)}\n"
            content += "#{Boreal.paint('Duration', :text)}: #{Boreal.paint(format_duration(duration), :bright)}\n"

            build_box(content, color: :error, width: 45)
          end

          def build_box(content, color:, width:)
            pastel_color = Boreal::Compat::PASTEL_MAP[color] || color
            TTY::Box.frame(
              content.strip,
              width: width,
              align: :left,
              border: :light,
              style: { border: { color: pastel_color } }
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
