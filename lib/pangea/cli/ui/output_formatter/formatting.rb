# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class OutputFormatter
        module Formatting
          def format_value(value)
            case value
            when String then truncate_string(value)
            when Array then format_array(value)
            when Hash then @pastel.bright_black("{#{value.size} items}")
            when Numeric then @pastel.cyan(value.to_s)
            when TrueClass, FalseClass then @pastel.yellow(value.to_s)
            when NilClass then @pastel.bright_black('null')
            else @pastel.bright_black(value.to_s)
            end
          end

          def format_array(value)
            if value.empty?
              @pastel.bright_black('[]')
            elsif value.length > 3
              formatted = value.first(3).join(', ')
              @pastel.bright_black("[#{formatted}, ... +#{value.length - 3} more]")
            else
              @pastel.bright_black("[#{value.join(', ')}]")
            end
          end

          def truncate_string(str, max_length: 60)
            if str.length > max_length
              @pastel.bright_black("#{str[0...max_length - 3]}...")
            else
              @pastel.bright_black(str)
            end
          end
        end
      end
    end
  end
end
