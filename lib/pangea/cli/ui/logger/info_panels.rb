# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

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
              c << "#{Boreal.paint('Current', :text)}: #{Boreal.paint("$#{current}/month", :bright)}" if current
              c << "#{Boreal.paint('Estimated', :text)}: #{Boreal.paint("$#{estimated}/month", :bright)}" if estimated

              if savings && savings != 0
                role = savings > 0 ? :success : :error
                symbol = savings > 0 ? "+" : "-"
                c << "#{symbol} #{Boreal.paint('Savings', :text)}: #{Boreal.paint("$#{savings.abs}/month", role)}"
              end
            end

            display_box(content, title: "Cost Impact", color: :warning, width: 40)
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
                c << "#{Boreal.paint(label, :text)}: #{Boreal.paint(metrics[key], :bright)}" if metrics[key]
              end
            end

            return if content.empty?
            display_box(content, title: "Performance", color: :info, width: 50)
          end

          # Namespace information display
          def namespace_info(namespace_entity)
            content = build_content do |c|
              c << "#{Boreal.paint('Name', :text)}: #{Boreal.paint(namespace_entity.name, :bright)}"
              c << "#{Boreal.paint('Backend', :text)}: #{Boreal.paint(namespace_entity.state.type, :bright)}"

              case namespace_entity.state.type
              when 's3'
                c << "#{Boreal.paint('Bucket', :text)}: #{Boreal.paint(namespace_entity.state.bucket, :primary)}"
                c << "#{Boreal.paint('Region', :text)}: #{Boreal.paint(namespace_entity.state.region, :primary)}"
              when 'local'
                c << "#{Boreal.paint('Path', :text)}: #{Boreal.paint(namespace_entity.state.path, :primary)}"
              end

              if namespace_entity.description
                c << "#{Boreal.paint('Description', :text)}: #{Boreal.paint(namespace_entity.description, :muted)}"
              end
            end

            display_box(content, title: "Namespace", color: :primary, width: 60)
          end

          # Warning panel for important notices
          def warning_panel(title, warnings)
            content = Boreal.paint("! #{title}", :warning) + "\n\n"
            content += warnings.map { |w| "#{Boreal.paint('*', :warning)} #{Boreal.paint(w, :text)}" }.join("\n")

            display_box(content, color: :warning, width: 70, border: :thick)
          end

          # Command completion celebration
          def celebration(message, emoji = "*")
            say "\n#{emoji} #{Boreal.paint(message, :success)} #{emoji}"
            say Boreal.paint("-" * (message.length + 6), :muted)
          end
        end
      end
    end
  end
end
