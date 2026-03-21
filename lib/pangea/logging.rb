# frozen_string_literal: true

require 'tty-logger'

module Pangea
  # Centralized logging for the Pangea CLI.
  #
  # Provides structured logging with component context.
  # Uses tty-logger for terminal-friendly output.
  module Logging
    def self.logger
      @logger ||= TTY::Logger.new do |config|
        config.level = ENV.fetch('PANGEA_LOG_LEVEL', 'info').to_sym
      end
    end

    # Create a child logger with component context
    class ChildLogger
      attr_reader :context

      def initialize(parent, **context)
        @parent = parent
        @context = context
      end

      def debug(msg, **fields)
        @parent.debug(format_msg(msg), **@context.merge(fields))
      end

      def info(msg, **fields)
        @parent.info(format_msg(msg), **@context.merge(fields))
      end

      def warn(msg, **fields)
        @parent.warn(format_msg(msg), **@context.merge(fields))
      end

      def error(msg, **fields)
        @parent.error(format_msg(msg), **@context.merge(fields))
      end

      def measure(label, **fields, &block)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = block.call
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        debug("#{label} (#{elapsed.round(3)}s)", **fields)
        result
      end

      def child(**extra_context)
        ChildLogger.new(@parent, **@context.merge(extra_context))
      end

      private

      def format_msg(msg)
        prefix = @context[:component] ? "[#{@context[:component]}] " : ''
        "#{prefix}#{msg}"
      end
    end

    def self.logger
      @logger ||= TTY::Logger.new do |config|
        config.level = ENV.fetch('PANGEA_LOG_LEVEL', 'info').to_sym
      end
    end

    # Allow logger.child(component: 'TemplateCompiler')
    class << self
      def child(**context)
        ChildLogger.new(logger, **context)
      end
    end

    # Make logger.child work on the logger instance too
    module LoggerExtensions
      def child(**context)
        Logging::ChildLogger.new(self, **context)
      end
    end
  end
end

# Extend TTY::Logger with child support
TTY::Logger.prepend(Pangea::Logging::LoggerExtensions)
