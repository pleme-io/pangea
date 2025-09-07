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