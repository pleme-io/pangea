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
require 'pangea/version'
require_relative 'banner/operation_summary'

module Pangea
  module CLI
    module UI
      # Beautiful banner and branding for Pangea
      class Banner
        def initialize
          @pastel = Pastel.new
          @operation_summary = OperationSummary.new(@pastel)
        end
        
        # Main Pangea banner with ASCII art
        def welcome
          box_content = <<~BANNER
            #{@pastel.bright_cyan('██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗ █████╗')}
            #{@pastel.bright_cyan('██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝██╔══██╗')}
            #{@pastel.bright_cyan('██████╔╝███████║██╔██╗ ██║██║  ███╗█████╗  ███████║')}
            #{@pastel.bright_cyan('██╔═══╝ ██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██║')}
            #{@pastel.bright_cyan('██║     ██║  ██║██║ ╚████║╚██████╔╝███████╗██║  ██║')}
            #{@pastel.bright_cyan('╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝')}
            
            #{@pastel.bright_white('🌍 Beautiful Infrastructure Management')}
            #{@pastel.bright_black("v#{Pangea::VERSION} • Ruby DSL → Terraform JSON")}
          BANNER
          
          TTY::Box.frame(
            box_content,
            width: 70,
            align: :center,
            border: :thick,
            style: {
              border: {
                top: @pastel.bright_cyan('─'),
                bottom: @pastel.bright_cyan('─'),
                left: @pastel.bright_cyan('│'),
                right: @pastel.bright_cyan('│'),
                top_left: @pastel.bright_cyan('╭'),
                top_right: @pastel.bright_cyan('╮'),
                bottom_left: @pastel.bright_cyan('╰'),
                bottom_right: @pastel.bright_cyan('╯')
              }
            }
          )
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
          
          puts @pastel.bright_cyan("#{emoji} Pangea#{command_text}") + 
               @pastel.bright_black(" v#{Pangea::VERSION}")
          puts @pastel.bright_black("─" * 50)
        end
        
        # Operation status banners
        def success(title, details = nil)
          icon = @pastel.bright_green('✅')
          title_text = @pastel.bright_green(title)
          
          content = "#{icon} #{title_text}"
          content += "\n#{@pastel.bright_black(details)}" if details
          
          TTY::Box.frame(
            content,
            width: [content.length + 8, 60].max,
            align: :center,
            border: :light,
            style: {
              border: {
                color: :green
              }
            }
          )
        end
        
        def error(title, details = nil, suggestions = [])
          icon = @pastel.bright_red('❌')
          title_text = @pastel.bright_red(title)
          
          content = "#{icon} #{title_text}"
          content += "\n\n#{@pastel.white(details)}" if details
          
          if suggestions.any?
            content += "\n\n#{@pastel.bright_yellow('💡 Suggestions:')}"
            suggestions.each do |suggestion|
              content += "\n  #{@pastel.yellow('•')} #{@pastel.white(suggestion)}"
            end
          end
          
          TTY::Box.frame(
            content,
            width: 70,
            align: :left,
            border: :thick,
            style: {
              border: {
                color: :red
              }
            }
          )
        end
        
        def warning(title, details = nil)
          icon = @pastel.bright_yellow('⚠️')
          title_text = @pastel.bright_yellow(title)
          
          content = "#{icon} #{title_text}"
          content += "\n#{@pastel.white(details)}" if details
          
          TTY::Box.frame(
            content,
            width: [content.length + 8, 60].max,
            align: :center,
            border: :light,
            style: {
              border: {
                color: :yellow
              }
            }
          )
        end
        
        # Information panels
        def info_panel(title, items)
          content = @pastel.bright_cyan("ℹ️  #{title}") + "\n\n"
          
          items.each do |key, value|
            content += "#{@pastel.bright_white(key.to_s.ljust(15))}: #{@pastel.white(value)}\n"
          end
          
          TTY::Box.frame(
            content.strip,
            width: 70,
            align: :left,
            border: :light,
            style: {
              border: {
                color: :cyan
              }
            }
          )
        end
        
        # Summary panels for operations
        def operation_summary(operation, stats)
          @operation_summary.render(operation, stats)
        end
      end
    end
  end
end