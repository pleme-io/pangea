# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class Logger
        # Resource display methods for the Logger
        module ResourceDisplay
          # Resource actions
          def resource_action(action, resource_type, resource_name, status = nil)
            symbols = { create: "+", update: "~", delete: "-", replace: "±" }
            roles = { create: :create, update: :update, delete: :delete, replace: :replace }

            action_symbol = symbols[action] || "?"
            action_role = roles[action] || :text

            message = "#{action_symbol} #{resource_type}.#{resource_name}"

            if status
              status_role = status == :success ? :success : :error
              status_text = status == :success ? "✓" : "✗"
              message += " #{Boreal.paint(status_text, status_role)}"
            end

            say message, color: action_role
          end

          # Resource status with enhanced formatting
          def resource_status(resource_type, resource_name, action, status = nil, details = nil)
            style = ACTION_STYLES[action] || ACTION_STYLES[:default]
            action_symbol = Boreal.paint(style[:symbol], style[:role])

            resource_display = "#{Boreal.paint(resource_type, :bright)}.#{Boreal.paint(resource_name, :primary)}"

            status_indicator = if status && (indicator = STATUS_INDICATORS[status])
                                status_role = { success: :success, error: :error,
                                               warning: :warning, pending: :info }[status] || :text
                                Boreal.paint(indicator, status_role)
                              else
                                ""
                              end

            message = "#{action_symbol} #{resource_display}#{status_indicator}"
            message += " #{Boreal.paint("(#{details})", :muted)}" if details

            say message
          end
        end
      end
    end
  end
end
