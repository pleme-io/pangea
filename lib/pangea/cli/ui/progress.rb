# frozen_string_literal: true

require 'tty-progressbar'
require 'pastel'

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
          total_stages = stages.length
          current = 0
          
          bar = TTY::ProgressBar.new(
            "#{title} [:bar] :current/:total :stage",
            total: total_stages,
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
      
      # Progress animations for specific operations
      module Animations
        # Compilation progress with file counter
        def self.compilation(total_files)
          Progress.new.single("Compiling templates", total: total_files) do |bar|
            yield -> (file) { 
              bar.log("  → #{file}")
              bar.advance 
            }
          end
        end
        
        # Resource creation with parallel bars
        def self.resource_creation(resources)
          Progress.new.multi("Creating resources") do |multi|
            bars = {}
            
            resources.each do |type, items|
              bars[type] = multi.register(
                type,
                "#{type.capitalize}",
                total: items.count
              )
            end
            
            yield -> (type) { bars[type]&.advance }
          end
        end
        
        # State operations with stages
        def self.state_operation(operation)
          stages = case operation
          when :init
            ["Checking backend", "Creating bucket", "Enabling versioning", "Setting up locking"]
          when :lock
            ["Acquiring lock", "Verifying ownership", "Recording metadata"]
          when :unlock
            ["Verifying ownership", "Releasing lock", "Cleaning up"]
          else
            ["Starting", "Processing", "Finalizing"]
          end
          
          Progress.new.stages("#{operation.capitalize} state", stages: stages) do |progress|
            yield -> (stage) { progress.complete_stage(stage) }
          end
        end
      end
    end
  end
end