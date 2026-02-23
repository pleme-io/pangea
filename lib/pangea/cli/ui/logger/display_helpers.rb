# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class Logger
        # Display helper methods for the Logger
        module DisplayHelpers
          # Progress messages
          def step(number, total, message)
            say "[#{number}/#{total}] #{message}", color: :muted
          end

          # File operations
          def file_action(action, path)
            action_texts = { create: "Creating", update: "Updating", delete: "Deleting", read: "Reading" }
            action_text = action_texts[action] || action.to_s.capitalize
            info "#{action_text} #{path}"
          end

          # Code display
          def code(content, language: :ruby)
            say "```#{language}", color: :muted
            say content
            say "```", color: :muted
          end

          # Error context
          def error_context(error, file: nil, line: nil)
            error "#{error.class}: #{error.message}"

            if file && line
              say "  Location: #{file}:#{line}", color: :muted
            end

            if ENV['DEBUG'] && error.backtrace
              say "\nBacktrace:", color: :muted
              error.backtrace.first(10).each do |frame|
                say "  #{frame}", color: :muted
              end
            end
          end

          # Beautiful diff display
          def diff_line(type, content)
            diff_roles = {
              add:     { prefix: "+ ", role: :added },
              remove:  { prefix: "- ", role: :removed },
              context: { prefix: "  ", role: :muted },
              header:  { prefix: "@@ ", suffix: " @@", role: :primary }
            }

            style = diff_roles[type]
            return unless style

            formatted_content = style[:suffix] ? "#{content}#{style[:suffix]}" : content
            say Boreal.paint("#{style[:prefix]}#{formatted_content}", style[:role])
          end

          # Template processing status
          def template_status(name, action, duration = nil)
            icon = TEMPLATE_ICONS[action] || TEMPLATE_ICONS[:default]

            action_texts = {
              compiling:  { text: 'compiling...', role: :update },
              compiled:   { text: 'compiled', role: :success },
              failed:     { text: 'failed', role: :error },
              validating: { text: 'validating...', role: :info },
              validated:  { text: 'validated', role: :success }
            }

            message = "#{icon} Template #{Boreal.paint(name, :bright)}"

            if (action_info = action_texts[action])
              message += " #{Boreal.paint(action_info[:text], action_info[:role])}"
              message += " #{Boreal.paint("(#{duration}s)", :muted)}" if duration && action == :compiled
            end

            say message
          end
        end
      end
    end
  end
end
