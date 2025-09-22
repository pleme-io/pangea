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


require 'tty-table'
require 'pastel'

module Pangea
  module CLI
    module UI
      # Enhanced Table UI component for displaying beautiful tabular data
      class Table
        def initialize(headers = nil, rows = [], options = {})
          @pastel = Pastel.new
          @table = TTY::Table.new(headers, rows)
          
          # Enhanced default options
          @options = {
            border: :unicode,
            padding: [0, 1],
            resize: true,
            multiline: true,
            style: {
              border: {
                top: @pastel.bright_cyan('─'),
                bottom: @pastel.bright_cyan('─'),
                left: @pastel.bright_cyan('│'),
                right: @pastel.bright_cyan('│'),
                top_left: @pastel.bright_cyan('┌'),
                top_right: @pastel.bright_cyan('┐'),
                bottom_left: @pastel.bright_cyan('└'),
                bottom_right: @pastel.bright_cyan('┘'),
                top_mid: @pastel.bright_cyan('┬'),
                mid: @pastel.bright_cyan('─'),
                mid_left: @pastel.bright_cyan('├'),
                mid_right: @pastel.bright_cyan('┤'),
                mid_mid: @pastel.bright_cyan('┼'),
                bottom_mid: @pastel.bright_cyan('┴')
              }
            }
          }.merge(options)
        end
        
        def render
          @table.render(:unicode, @options)
        end
        
        def add_row(row)
          @table << row
        end
        
        def to_s
          render
        end
        
        # Enhanced class methods for specific table types
        
        # Resource summary table
        def self.resource_summary(resources)
          pastel = Pastel.new
          
          headers = [
            pastel.bright_white('Resource'),
            pastel.bright_white('Action'),
            pastel.bright_white('Status'),
            pastel.bright_white('Details')
          ]
          
          rows = resources.map do |resource|
            action_color = case resource[:action]
                          when :create then :bright_green
                          when :update then :bright_yellow
                          when :delete then :bright_red
                          when :replace then :bright_magenta
                          else :white
                          end
            
            status_display = case resource[:status]
                            when :success then pastel.bright_green('✓ Success')
                            when :error then pastel.bright_red('✗ Error')
                            when :warning then pastel.bright_yellow('⚠ Warning')
                            when :pending then pastel.bright_blue('⧖ Pending')
                            else pastel.bright_black('Unknown')
                            end
            
            [
              "#{pastel.cyan(resource[:type])}.#{pastel.white(resource[:name])}",
              pastel.decorate(resource[:action].to_s.capitalize, action_color),
              status_display,
              pastel.bright_black(resource[:details] || '')
            ]
          end
          
          new(headers, rows).render
        end
        
        # Plan summary table
        def self.plan_summary(plan_data)
          pastel = Pastel.new
          
          headers = [
            pastel.bright_white('Resource'),
            pastel.bright_white('Action'),
            pastel.bright_white('Reason')
          ]
          
          rows = plan_data.map do |item|
            action_symbol = case item[:action]
                           when :create then pastel.bright_green('+ ')
                           when :update then pastel.bright_yellow('~ ')
                           when :delete then pastel.bright_red('- ')
                           when :replace then pastel.bright_magenta('± ')
                           else '  '
                           end
            
            [
              "#{action_symbol}#{pastel.cyan(item[:type])}.#{pastel.white(item[:name])}",
              item[:action].to_s.capitalize,
              pastel.bright_black(item[:reason] || '')
            ]
          end
          
          new(headers, rows).render
        end
        
        # Template summary table
        def self.template_summary(templates)
          pastel = Pastel.new
          
          headers = [
            pastel.bright_white('Template'),
            pastel.bright_white('Resources'),
            pastel.bright_white('Status'),
            pastel.bright_white('Duration')
          ]
          
          rows = templates.map do |template|
            status_display = case template[:status]
                            when :compiled then pastel.bright_green('✓ Compiled')
                            when :failed then pastel.bright_red('✗ Failed')
                            when :validating then pastel.bright_blue('🔍 Validating')
                            when :compiling then pastel.bright_yellow('⚙️ Compiling')
                            else pastel.bright_black('Unknown')
                            end
            
            duration_display = if template[:duration]
                              if template[:duration] < 1
                                "#{(template[:duration] * 1000).round}ms"
                              else
                                "#{template[:duration].round(1)}s"
                              end
                              else
                                ''
                              end
            
            [
              pastel.bright_white(template[:name]),
              pastel.cyan(template[:resource_count].to_s),
              status_display,
              pastel.bright_black(duration_display)
            ]
          end
          
          new(headers, rows).render
        end
        
        # Namespace table
        def self.namespace_summary(namespaces)
          pastel = Pastel.new
          
          headers = [
            pastel.bright_white('Namespace'),
            pastel.bright_white('Backend'),
            pastel.bright_white('Location'),
            pastel.bright_white('Description')
          ]
          
          rows = namespaces.map do |ns|
            backend_icon = case ns[:backend_type]
                          when 's3' then '☁️'
                          when 'local' then '📁'
                          when 'remote' then '🌐'
                          else '❓'
                          end
            
            [
              pastel.bright_white(ns[:name]),
              "#{backend_icon} #{ns[:backend_type]}",
              pastel.cyan(ns[:location] || ''),
              pastel.bright_black(ns[:description] || '')
            ]
          end
          
          new(headers, rows).render
        end
        
        # Cost breakdown table
        def self.cost_breakdown(cost_data)
          pastel = Pastel.new
          
          headers = [
            pastel.bright_white('Service'),
            pastel.bright_white('Current'),
            pastel.bright_white('Estimated'),
            pastel.bright_white('Change')
          ]
          
          rows = cost_data.map do |item|
            change = item[:estimated] - item[:current]
            change_display = if change > 0
                            pastel.bright_red("+$#{change.abs}/mo")
                           elsif change < 0
                            pastel.bright_green("-$#{change.abs}/mo")
                           else
                            pastel.bright_black("No change")
                           end
            
            [
              pastel.white(item[:service]),
              "$#{item[:current]}/mo",
              "$#{item[:estimated]}/mo",
              change_display
            ]
          end
          
          new(headers, rows).render
        end
        
        # Quick table creation with enhanced styling
        def self.simple(headers, rows, title: nil)
          pastel = Pastel.new
          
          # Format headers with color
          colored_headers = headers.map { |h| pastel.bright_white(h) }
          
          table = new(colored_headers, rows)
          
          result = table.render
          
          if title
            title_line = pastel.bright_cyan("#{title}")
            separator = pastel.bright_cyan("─" * title.length)
            result = "#{title_line}\n#{separator}\n#{result}"
          end
          
          result
        end
        
        # Class method for quick table creation (backward compatibility)
        def self.print(headers, rows, options = {})
          new(headers, rows, options).render
        end
      end
    end
  end
end