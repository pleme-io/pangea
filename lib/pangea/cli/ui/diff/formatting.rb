# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'json'

module Pangea
  module CLI
    module UI
      module Diff
        # Value formatting and action styling for diff display
        module Formatting
          # Action icons and Boreal roles for terraform operations
          ACTION_STYLES = {
            create:  ['[+]', :create],
            update:  ['[~]', :update],
            replace: ['[+/-]', :replace],
            destroy: ['[-]', :delete],
            read:    ['[<-]', :info],
            unknown: ['[?]', :text]
          }.freeze

          module_function

          def action_style(action)
            ACTION_STYLES.fetch(action, ACTION_STYLES[:unknown])
          end

          def format_value_change(old_val, new_val)
            if old_val.length > 30 || new_val.length > 30
              # Multi-line diff for long values
              "\n    #{Boreal.paint("- #{old_val}", :removed)}\n    #{Boreal.paint("+ #{new_val}", :added)}"
            else
              # Inline diff for short values
              "#{Boreal.paint(old_val, :removed)} -> #{Boreal.paint(new_val, :added)}"
            end
          end

          def format_value(value)
            case value
            when String
              value =~ /\n/ ? "\n#{value.lines.map { |l| "    #{l}" }.join}" : value
            when Hash, Array
              JSON.pretty_generate(value)
            else
              value.to_s
            end
          end
        end
      end
    end
  end
end
