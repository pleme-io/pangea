# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'

module Pangea
  module CLI
    module UI
      class Table
        # Formatters for table row styling and display
        module Formatters
          # Action → Boreal role mappings
          ACTION_ROLES = {
            create: :create,
            update: :update,
            delete: :delete,
            replace: :replace
          }.freeze

          STATUS_DISPLAYS = {
            success: ['✓ Success', :success],
            error: ['✗ Error', :error],
            warning: ['⚠ Warning', :warning],
            pending: ['⧖ Pending', :info]
          }.freeze

          ACTION_SYMBOLS = {
            create: ['+ ', :create],
            update: ['~ ', :update],
            delete: ['- ', :delete],
            replace: ['± ', :replace]
          }.freeze

          TEMPLATE_STATUS = {
            compiled: ['✓ Compiled', :success],
            failed: ['✗ Failed', :error],
            validating: ['🔍 Validating', :info],
            compiling: ['⚙️ Compiling', :update]
          }.freeze

          BACKEND_ICONS = {
            's3' => '☁️',
            'local' => '📁',
            'remote' => '🌐'
          }.freeze

          module_function

          def format_resource_row(resource)
            action_role = ACTION_ROLES[resource[:action]] || :text
            status_text, status_role = STATUS_DISPLAYS[resource[:status]] || ['Unknown', :muted]

            [
              "#{Boreal.paint(resource[:type], :primary)}.#{Boreal.paint(resource[:name], :text)}",
              Boreal.paint(resource[:action].to_s.capitalize, action_role),
              Boreal.paint(status_text, status_role),
              Boreal.paint(resource[:details] || '', :muted)
            ]
          end

          def format_plan_row(item)
            symbol, role = ACTION_SYMBOLS[item[:action]] || ['  ', :text]

            [
              "#{Boreal.paint(symbol, role)}#{Boreal.paint(item[:type], :primary)}.#{Boreal.paint(item[:name], :text)}",
              item[:action].to_s.capitalize,
              Boreal.paint(item[:reason] || '', :muted)
            ]
          end

          def format_template_row(template)
            status_text, status_role = TEMPLATE_STATUS[template[:status]] || ['Unknown', :muted]
            duration = format_duration(template[:duration])

            [
              Boreal.paint(template[:name], :bright),
              Boreal.paint(template[:resource_count].to_s, :primary),
              Boreal.paint(status_text, status_role),
              Boreal.paint(duration, :muted)
            ]
          end

          def format_duration(duration)
            return '' unless duration
            duration < 1 ? "#{(duration * 1000).round}ms" : "#{duration.round(1)}s"
          end

          def format_namespace_row(ns)
            backend_icon = BACKEND_ICONS[ns[:backend_type]] || '❓'

            [
              Boreal.paint(ns[:name], :bright),
              "#{backend_icon} #{ns[:backend_type]}",
              Boreal.paint(ns[:location] || '', :primary),
              Boreal.paint(ns[:description] || '', :muted)
            ]
          end

          def format_cost_row(item)
            change = item[:estimated] - item[:current]
            change_display = format_cost_change(change)

            [
              Boreal.paint(item[:service], :text),
              "$#{item[:current]}/mo",
              "$#{item[:estimated]}/mo",
              change_display
            ]
          end

          def format_cost_change(change)
            if change > 0
              Boreal.paint("+$#{change.abs}/mo", :error)
            elsif change < 0
              Boreal.paint("-$#{change.abs}/mo", :success)
            else
              Boreal.paint("No change", :muted)
            end
          end
        end
      end
    end
  end
end
