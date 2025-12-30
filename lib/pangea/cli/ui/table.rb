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
require_relative 'table/formatters'

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

        # Resource summary table
        def self.resource_summary(resources)
          render_table(
            headers: %w[Resource Action Status Details],
            rows: resources.map { |r| Formatters.format_resource_row(r) }
          )
        end

        # Plan summary table
        def self.plan_summary(plan_data)
          render_table(
            headers: %w[Resource Action Reason],
            rows: plan_data.map { |item| Formatters.format_plan_row(item) }
          )
        end

        # Template summary table
        def self.template_summary(templates)
          render_table(
            headers: %w[Template Resources Status Duration],
            rows: templates.map { |t| Formatters.format_template_row(t) }
          )
        end

        # Namespace table
        def self.namespace_summary(namespaces)
          render_table(
            headers: %w[Namespace Backend Location Description],
            rows: namespaces.map { |ns| Formatters.format_namespace_row(ns) }
          )
        end

        # Cost breakdown table
        def self.cost_breakdown(cost_data)
          render_table(
            headers: %w[Service Current Estimated Change],
            rows: cost_data.map { |item| Formatters.format_cost_row(item) }
          )
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

        private_class_method :render_table
      end
    end
  end
end
