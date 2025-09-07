# frozen_string_literal: true

require 'tty-table'

module Pangea
  module CLI
    module UI
      # Table UI component for displaying tabular data
      class Table
        def initialize(headers = nil, rows = [], options = {})
          @table = TTY::Table.new(headers, rows)
          @options = {
            border: :unicode,
            padding: [0, 1]
          }.merge(options)
        end
        
        def render
          @table.render(@options[:style] || :unicode, @options)
        end
        
        def add_row(row)
          @table << row
        end
        
        def to_s
          render
        end
        
        # Class method for quick table creation
        def self.print(headers, rows, options = {})
          new(headers, rows, options).render
        end
      end
    end
  end
end