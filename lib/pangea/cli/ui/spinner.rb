# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-spinner'

module Pangea
  module CLI
    module UI
      # Enhanced Spinner UI component for showing progress
      class Spinner
        def initialize(message = nil, options = {})
          format = options.fetch(:format, :dots)

          # Enhanced spinner with beautiful formatting
          spinner_format = "[:spinner] #{Boreal.paint(message, :text)}"

          @spinner = TTY::Spinner.new(
            spinner_format,
            format: format,
            hide_cursor: true,
            success_mark: Boreal.paint('✅', :success),
            error_mark: Boreal.paint('❌', :error),
            clear: options.fetch(:clear, false),
            interval: options.fetch(:interval, 10)
          )

          @start_time = nil
        end

        def start
          @start_time = Time.now
          @spinner.start
        end

        def stop
          @spinner.stop
        end

        def success(message = nil)
          formatted_message = if message && @start_time
            duration = Time.now - @start_time
            "#{Boreal.paint(message, :success)} #{Boreal.paint("(#{format_duration(duration)})", :muted)}"
          else
            message
          end
          @spinner.success(formatted_message)
        end

        def error(message = nil)
          @spinner.error(message ? Boreal.paint(message, :error) : nil)
        end

        def warning(message = nil)
          @spinner.success("⚠️  #{message ? Boreal.paint(message, :warning) : nil}")
        end

        def update(message)
          @spinner.update(title: "[:spinner] #{Boreal.paint(message, :text)}")
        end

        def spin
          start
          result = yield
          success
          result
        rescue => e
          error(e.message)
          raise e
        ensure
          stop
        end

        # Multi-stage spinner for complex operations
        def self.multi_stage(stages)
          stages.each_with_index do |stage_name, index|
            stage_spinner = new("#{stage_name} (#{index + 1}/#{stages.length})")

            begin
              stage_spinner.start
              yield(stage_spinner, stage_name)
              stage_spinner.success("#{stage_name} complete")
            rescue => e
              stage_spinner.error("#{stage_name} failed")
              raise
            end
          end
        end

        # Specialized spinners for common operations
        OPERATION_FORMATS = {
          compilation: { format: :bouncing_ball, default_message: "Compiling templates" },
          network: { format: :pulse, default_message: "Network operation" },
          file: { format: :classic, default_message: "File operation" }
        }.freeze

        TERRAFORM_MESSAGES = {
          init:     "Initializing Terraform",
          plan:     "Planning infrastructure",
          apply:    "Applying changes",
          destroy:  "Destroying resources",
          validate: "Validating configuration",
          refresh:  "Refreshing state"
        }.freeze

        class << self
          def compilation(message = nil)
            create_spinner(:compilation, message)
          end

          def network_operation(message = nil)
            create_spinner(:network, message)
          end

          def file_operation(message = nil)
            create_spinner(:file, message)
          end

          def terraform_operation(operation)
            message = TERRAFORM_MESSAGES[operation] || "Running Terraform"
            new(message, format: :arrow)
          end

          private

          def create_spinner(type, message = nil)
            config = OPERATION_FORMATS[type]
            new(message || config[:default_message], format: config[:format])
          end
        end

        private

        def format_duration(seconds)
          case seconds
          when 0...1 then "#{(seconds * 1000).round}ms"
          when 1...60 then "#{seconds.round(1)}s"
          else
            minutes, remaining_seconds = seconds.divmod(60)
            "#{minutes.floor}m #{remaining_seconds.round}s"
          end
        end
      end
    end
  end
end
