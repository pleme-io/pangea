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

require 'tty-progressbar'
require 'pastel'

require_relative 'progress/wrappers'
require_relative 'progress/animations'

module Pangea
  module CLI
    module UI
      # Enhanced progress indicators for long operations
      class Progress
        def initialize
          @pastel = Pastel.new
        end

        # Multi-bar progress for parallel operations
        def multi(title, &block)
          TTY::ProgressBar::Multi.new(title) do |multibar|
            yield(MultiBarWrapper.new(multibar, @pastel))
          end
        end

        # Single progress bar
        def single(title, total:, &block)
          bar = create_bar(title, total)

          begin
            yield(SingleBarWrapper.new(bar))
          ensure
            bar.finish
          end
        end

        # Indeterminate progress (spinner with stages)
        def stages(title, stages:, &block)
          bar = TTY::ProgressBar.new(
            "#{title} [:bar] :current/:total :stage",
            total: stages.length,
            bar_format: :block,
            clear: true,
            width: 20
          )

          wrapper = StageWrapper.new(bar, stages)
          yield(wrapper)

          bar.finish
        end

        # File transfer progress
        def transfer(title, total_bytes:)
          TTY::ProgressBar.new(
            "#{title} [:bar] :percent :current_byte/:total_byte :rate/s :eta",
            total: total_bytes,
            bar_format: :block,
            clear: true,
            width: 30
          )
        end

        private

        def create_bar(title, total)
          TTY::ProgressBar.new(
            "#{title} [:bar] :percent :current/:total :elapsed",
            total: total,
            bar_format: :block,
            clear: true,
            width: 30,
            complete: @pastel.green("█"),
            incomplete: @pastel.bright_black("░"),
            head: @pastel.yellow("█")
          )
        end
      end
    end
  end
end
