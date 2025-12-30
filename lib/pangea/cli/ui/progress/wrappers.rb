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

module Pangea
  module CLI
    module UI
      # Wrapper for multi-bar operations
      class MultiBarWrapper
        def initialize(multibar, pastel)
          @multibar = multibar
          @pastel = pastel
          @bars = {}
        end

        def register(name, title, total:)
          format = "#{title} [:bar] :percent :current/:total"

          bar = @multibar.register(format, total: total) do |config|
            config.bar_format = :block
            config.clear = true
            config.width = 25
            config.complete = @pastel.green("█")
            config.incomplete = @pastel.bright_black("░")
            config.head = @pastel.yellow("█")
          end

          @bars[name] = bar
          bar
        end

        def advance(name, by: 1)
          @bars[name]&.advance(by)
        end

        def finish(name)
          @bars[name]&.finish
        end

        def update(name, **tokens)
          @bars[name]&.update(tokens)
        end
      end

      # Wrapper for single bar operations
      class SingleBarWrapper
        def initialize(bar)
          @bar = bar
        end

        def advance(by: 1)
          @bar.advance(by)
        end

        def update(**tokens)
          @bar.update(tokens)
        end

        def current=(value)
          @bar.current = value
        end

        def log(message)
          @bar.log(message)
        end
      end

      # Wrapper for stage-based progress
      class StageWrapper
        def initialize(bar, stages)
          @bar = bar
          @stages = stages
          @current = 0
        end

        def next_stage
          return if @current >= @stages.length

          @bar.update(stage: @stages[@current])
          @bar.advance
          @current += 1
        end

        def complete_stage(stage_name)
          idx = @stages.index(stage_name)
          return unless idx

          while @current <= idx
            next_stage
          end
        end

        def update(**tokens)
          @bar.update(tokens)
        end
      end
    end
  end
end
