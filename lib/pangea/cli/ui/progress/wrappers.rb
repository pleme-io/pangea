# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'

module Pangea
  module CLI
    module UI
      # Wrapper for multi-bar operations
      class MultiBarWrapper
        def initialize(multibar)
          @multibar = multibar
          @bars = {}
        end

        def register(name, title, total:)
          format = "#{title} [:bar] :percent :current/:total"

          bar = @multibar.register(format, total: total) do |config|
            config.bar_format = :block
            config.clear = true
            config.width = 25
            config.complete = Boreal.paint("█", :success)
            config.incomplete = Boreal.paint("░", :muted)
            config.head = Boreal.paint("█", :update)
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
