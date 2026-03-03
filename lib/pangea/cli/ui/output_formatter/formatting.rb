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
            when Hash then Boreal.paint("{#{value.size} items}", :muted)
            when Numeric then Boreal.paint(value.to_s, :primary)
            when TrueClass, FalseClass then Boreal.paint(value.to_s, :update)
            when NilClass then Boreal.paint('null', :muted)
            else Boreal.paint(value.to_s, :muted)
            end
          end

          def format_array(value)
            if value.empty?
              Boreal.paint('[]', :muted)
            elsif value.length > 3
              formatted = value.first(3).join(', ')
              Boreal.paint("[#{formatted}, ... +#{value.length - 3} more]", :muted)
            else
              Boreal.paint("[#{value.join(', ')}]", :muted)
            end
          end

          def truncate_string(str, max_length: 60)
            if str.length > max_length
              Boreal.paint("#{str[0...max_length - 3]}...", :muted)
            else
              Boreal.paint(str, :muted)
            end
          end
        end
      end
    end
  end
end
