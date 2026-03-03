# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-box'
require 'pangea/version'
require_relative 'banner/operation_summary'

module Pangea
  module CLI
    module UI
      # Beautiful banner and branding for Pangea
      class Banner
        def initialize
          @operation_summary = OperationSummary.new
        end

        # Main Pangea banner with ASCII art
        def welcome
          box_content = <<~BANNER
            #{Boreal.paint('██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗ █████╗', :primary)}
            #{Boreal.paint('██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝██╔══██╗', :primary)}
            #{Boreal.paint('██████╔╝███████║██╔██╗ ██║██║  ███╗█████╗  ███████║', :primary)}
            #{Boreal.paint('██╔═══╝ ██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██║', :primary)}
            #{Boreal.paint('██║     ██║  ██║██║ ╚████║╚██████╔╝███████╗██║  ██║', :primary)}
            #{Boreal.paint('╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝', :primary)}

            #{Boreal.paint('🌍 Beautiful Infrastructure Management', :bright)}
            #{Boreal.paint("v#{Pangea::VERSION} • Ruby DSL → Terraform JSON", :muted)}
          BANNER

          boreal_box = Boreal::Components::Box.new
          boreal_box.frame(box_content, width: 70, align: :center, role: :primary, border: :thick)
        end

        # Compact header for commands
        def header(command = nil)
          emoji = case command
                 when 'plan' then '📋'
                 when 'apply' then '🚀'
                 when 'destroy' then '💥'
                 when 'inspect' then '🔍'
                 when 'import' then '📥'
                 else '🌍'
                 end

          command_text = command ? " #{command.capitalize}" : ""

          puts Boreal.paint("#{emoji} Pangea#{command_text}", :primary) +
               " #{Boreal.paint("v#{Pangea::VERSION}", :muted)}"
          puts Boreal.paint("─" * 50, :muted)
        end

        # Operation status banners
        def success(title, details = nil)
          Boreal::Components::Box.success(title, details)
        end

        def error(title, details = nil, suggestions = [])
          Boreal::Components::Box.error(title, details, suggestions: suggestions)
        end

        def warning(title, details = nil)
          Boreal::Components::Box.warning(title, details)
        end

        # Information panels
        def info_panel(title, items)
          Boreal::Components::Box.info(title, items)
        end

        # Summary panels for operations
        def operation_summary(operation, stats)
          @operation_summary.render(operation, stats)
        end
      end
    end
  end
end
