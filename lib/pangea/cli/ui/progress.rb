# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-progressbar'

require_relative 'progress/wrappers'
require_relative 'progress/animations'

module Pangea
  module CLI
    module UI
      # Enhanced progress indicators for long operations
      class Progress
        # Multi-bar progress for parallel operations
        def multi(title, &block)
          TTY::ProgressBar::Multi.new(title) do |multibar|
            yield(MultiBarWrapper.new(multibar))
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
            complete: Boreal.paint("█", :success),
            incomplete: Boreal.paint("░", :muted),
            head: Boreal.paint("█", :update)
          )
        end
      end
    end
  end
end
