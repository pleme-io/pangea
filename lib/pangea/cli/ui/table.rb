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
          border_chars = %w[─ ─ │ │ ┌ ┐ └ ┘ ┬ ─ ├ ┤ ┼ ┴]
          border_symbols = %i[top bottom left right top_left top_right bottom_left bottom_right 
                             top_mid mid mid_left mid_right mid_mid bottom_mid]
          
          @options = {
            padding: [0, 1],
            resize: true,
            multiline: true,
            style: {
              border: border_symbols.zip(border_chars).map { |sym, char| 
                [sym, @pastel.bright_cyan(char)]
              }.to_h
            }
          }.merge(options)
        end
        
        def render
          @table.render(:unicode, **@options)
        end
        
        def add_row(row)
          @table << row
        end
        
        def to_s
          render
        end
        
        # Enhanced class methods for specific table types
        
        # Color mappings
        ACTION_COLORS = {
          create: :bright_green,
          update: :bright_yellow,
          delete: :bright_red,
          replace: :bright_magenta
        }.freeze
        
        STATUS_DISPLAYS = {
          success: ['✓ Success', :bright_green],
          error: ['✗ Error', :bright_red],
          warning: ['⚠ Warning', :bright_yellow],
          pending: ['⧖ Pending', :bright_blue]
        }.freeze
        
        # Resource summary table
        def self.resource_summary(resources)
          render_table(
            headers: %w[Resource Action Status Details],
            rows: resources.map { |r| format_resource_row(r) }
          )
        end
        
        def self.format_resource_row(resource)
          pastel = Pastel.new
          action_color = ACTION_COLORS[resource[:action]] || :white
          status_text, status_color = STATUS_DISPLAYS[resource[:status]] || ['Unknown', :bright_black]
          
          [
            "#{pastel.cyan(resource[:type])}.#{pastel.white(resource[:name])}",
            pastel.decorate(resource[:action].to_s.capitalize, action_color),
            pastel.decorate(status_text, status_color),
            pastel.bright_black(resource[:details] || '')
          ]
        end
        
        # Action symbols for plan display
        ACTION_SYMBOLS = {
          create: ['+ ', :bright_green],
          update: ['~ ', :bright_yellow],
          delete: ['- ', :bright_red],
          replace: ['± ', :bright_magenta]
        }.freeze
        
        # Plan summary table
        def self.plan_summary(plan_data)
          render_table(
            headers: %w[Resource Action Reason],
            rows: plan_data.map { |item| format_plan_row(item) }
          )
        end
        
        def self.format_plan_row(item)
          pastel = Pastel.new
          symbol, color = ACTION_SYMBOLS[item[:action]] || ['  ', :white]
          
          [
            "#{pastel.decorate(symbol, color)}#{pastel.cyan(item[:type])}.#{pastel.white(item[:name])}",
            item[:action].to_s.capitalize,
            pastel.bright_black(item[:reason] || '')
          ]
        end
        
        # Template status displays
        TEMPLATE_STATUS = {
          compiled: ['✓ Compiled', :bright_green],
          failed: ['✗ Failed', :bright_red],
          validating: ['🔍 Validating', :bright_blue],
          compiling: ['⚙️ Compiling', :bright_yellow]
        }.freeze
        
        # Template summary table
        def self.template_summary(templates)
          render_table(
            headers: %w[Template Resources Status Duration],
            rows: templates.map { |t| format_template_row(t) }
          )
        end
        
        def self.format_template_row(template)
          pastel = Pastel.new
          status_text, status_color = TEMPLATE_STATUS[template[:status]] || ['Unknown', :bright_black]
          duration = format_duration(template[:duration])
          
          [
            pastel.bright_white(template[:name]),
            pastel.cyan(template[:resource_count].to_s),
            pastel.decorate(status_text, status_color),
            pastel.bright_black(duration)
          ]
        end
        
        def self.format_duration(duration)
          return '' unless duration
          duration < 1 ? "#{(duration * 1000).round}ms" : "#{duration.round(1)}s"
        end
        
        # Backend icons
        BACKEND_ICONS = {
          's3' => '☁️',
          'local' => '📁',
          'remote' => '🌐'
        }.freeze
        
        # Namespace table
        def self.namespace_summary(namespaces)
          render_table(
            headers: %w[Namespace Backend Location Description],
            rows: namespaces.map { |ns| format_namespace_row(ns) }
          )
        end
        
        def self.format_namespace_row(ns)
          pastel = Pastel.new
          backend_icon = BACKEND_ICONS[ns[:backend_type]] || '❓'
          
          [
            pastel.bright_white(ns[:name]),
            "#{backend_icon} #{ns[:backend_type]}",
            pastel.cyan(ns[:location] || ''),
            pastel.bright_black(ns[:description] || '')
          ]
        end
        
        # Cost breakdown table
        def self.cost_breakdown(cost_data)
          render_table(
            headers: %w[Service Current Estimated Change],
            rows: cost_data.map { |item| format_cost_row(item) }
          )
        end
        
        def self.format_cost_row(item)
          pastel = Pastel.new
          change = item[:estimated] - item[:current]
          
          change_display = format_cost_change(change, pastel)
          
          [
            pastel.white(item[:service]),
            "$#{item[:current]}/mo",
            "$#{item[:estimated]}/mo",
            change_display
          ]
        end
        
        def self.format_cost_change(change, pastel)
          if change > 0
            pastel.bright_red("+$#{change.abs}/mo")
          elsif change < 0
            pastel.bright_green("-$#{change.abs}/mo")
          else
            pastel.bright_black("No change")
          end
        end
        
        # Quick table creation with enhanced styling
        def self.simple(headers, rows, title: nil)
          result = render_table(headers: headers, rows: rows)
          
          if title
            pastel = Pastel.new
            title_line = pastel.bright_cyan(title)
            separator = pastel.bright_cyan("─" * title.length)
            result = "#{title_line}\n#{separator}\n#{result}"
          end
          
          result
        end
        
        # Class method for quick table creation (backward compatibility)
        def self.print(headers, rows, options = {})
          new(headers, rows, options).render
        end
        
        # Common render method
        def self.render_table(headers:, rows:)
          pastel = Pastel.new
          colored_headers = headers.map { |h| pastel.bright_white(h) }
          new(colored_headers, rows).render
        end
        
        private_class_method :format_resource_row, :format_plan_row, :format_template_row, 
                             :format_namespace_row, :format_cost_row, :format_cost_change, 
                             :format_duration, :render_table
      end
    end
  end
end