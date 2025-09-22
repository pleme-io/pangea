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

require 'json'
require 'time'
require 'securerandom'

module Pangea
  module Logging
    # Structured logger for debug mode with JSON and pretty output formats
    class StructuredLogger
      LEVELS = {
        debug: 0,
        info: 1,
        warn: 2,
        error: 3,
        fatal: 4
      }.freeze
      
      attr_reader :log_level, :output_format, :correlation_id
      
      def initialize(output: $stdout, level: :info, format: nil, correlation_id: nil)
        @output = output
        @log_level = LEVELS[level] || LEVELS[:info]
        @output_format = determine_format(format)
        @correlation_id = correlation_id || SecureRandom.uuid
        @metadata = {}
      end
      
      # Log methods for each level
      LEVELS.each do |level, value|
        define_method(level) do |message, **context|
          log(level, message, **context) if should_log?(level)
        end
      end
      
      # Add global metadata that will be included in all log entries
      def add_metadata(key, value)
        @metadata[key] = value
      end
      
      # Clear global metadata
      def clear_metadata
        @metadata.clear
      end
      
      # Create a child logger with additional context
      def child(**context)
        child_logger = self.class.new(
          output: @output,
          level: LEVELS.key(@log_level),
          format: @output_format,
          correlation_id: @correlation_id
        )
        child_logger.instance_variable_set(:@metadata, @metadata.merge(context))
        child_logger
      end
      
      # Measure execution time and log it
      def measure(operation_name, level: :info, **context)
        start_time = Time.now
        log_context = context.merge(
          operation: operation_name,
          status: 'started'
        )
        
        log(level, "Operation started: #{operation_name}", **log_context)
        
        begin
          result = yield
          
          duration = Time.now - start_time
          log_context.merge!(
            status: 'completed',
            duration_ms: (duration * 1000).round(2)
          )
          
          log(level, "Operation completed: #{operation_name}", **log_context)
          
          result
        rescue => e
          duration = Time.now - start_time
          log_context.merge!(
            status: 'failed',
            duration_ms: (duration * 1000).round(2),
            error: e.class.name,
            error_message: e.message
          )
          
          error("Operation failed: #{operation_name}", **log_context)
          raise
        end
      end
      
      # Log structured data (useful for metrics and analytics)
      def metric(name, value, unit: nil, **tags)
        context = {
          metric_name: name,
          metric_value: value,
          metric_unit: unit,
          metric_tags: tags
        }.compact
        
        info("Metric recorded: #{name}", **context)
      end
      
      private
      
      def log(level, message, **context)
        entry = build_log_entry(level, message, context)
        
        case @output_format
        when :json
          @output.puts JSON.generate(entry)
        when :pretty
          @output.puts format_pretty(entry)
        when :logfmt
          @output.puts format_logfmt(entry)
        else
          @output.puts format_simple(entry)
        end
        
        @output.flush if @output.respond_to?(:flush)
      end
      
      def build_log_entry(level, message, context)
        # Merge contexts in order: metadata, context, standard fields
        {
          timestamp: Time.now.iso8601(3),
          level: level.to_s.upcase,
          correlation_id: @correlation_id,
          message: message,
          **@metadata,
          **context,
          **system_context
        }.compact
      end
      
      def system_context
        {
          pid: Process.pid,
          thread_id: Thread.current.object_id,
          ruby_version: RUBY_VERSION
        }
      end
      
      def should_log?(level)
        LEVELS[level] >= @log_level
      end
      
      def determine_format(format)
        return format if format
        
        case ENV['PANGEA_LOG_FORMAT']
        when 'json' then :json
        when 'pretty' then :pretty
        when 'logfmt' then :logfmt
        when 'simple' then :simple
        else
          # Default to JSON in production, pretty in development
          ENV['PANGEA_ENV'] == 'production' ? :json : :pretty
        end
      end
      
      # Format implementations
      
      def format_pretty(entry)
        timestamp = Time.parse(entry[:timestamp]).strftime('%Y-%m-%d %H:%M:%S.%L')
        level = entry[:level].ljust(5)
        level_color = level_colors[entry[:level].downcase.to_sym]
        
        # Build context string
        context_items = entry.reject { |k, _| 
          %i[timestamp level message correlation_id pid thread_id ruby_version].include?(k) 
        }
        
        context_str = if context_items.any?
          " | " + context_items.map { |k, v| "#{k}=#{format_value(v)}" }.join(' ')
        else
          ""
        end
        
        # Apply color if available
        if defined?(Pastel) && level_color
          pastel = Pastel.new
          level = pastel.decorate(level, level_color)
        end
        
        "#{timestamp} [#{level}] #{entry[:message]}#{context_str}"
      end
      
      def format_json(entry)
        JSON.generate(entry)
      end
      
      def format_logfmt(entry)
        entry.map { |k, v| 
          value = v.to_s.include?(' ') ? "\"#{v}\"" : v
          "#{k}=#{value}"
        }.join(' ')
      end
      
      def format_simple(entry)
        "#{entry[:level]} - #{entry[:message]}"
      end
      
      def format_value(value)
        case value
        when String
          value.include?(' ') ? "\"#{value}\"" : value
        when Hash
          "{#{value.size} items}"
        when Array
          "[#{value.size} items]"
        else
          value.to_s
        end
      end
      
      def level_colors
        {
          debug: :bright_black,
          info: :bright_blue,
          warn: :bright_yellow,
          error: :bright_red,
          fatal: :bright_magenta
        }
      end
    end
    
    # Global logger instance
    class << self
      attr_writer :logger
      
      def logger
        @logger ||= StructuredLogger.new(
          level: ENV['PANGEA_LOG_LEVEL']&.to_sym || :info,
          format: ENV['PANGEA_LOG_FORMAT']&.to_sym
        )
      end
      
      # Delegate to logger instance
      def method_missing(method, *args, **kwargs, &block)
        if logger.respond_to?(method)
          logger.send(method, *args, **kwargs, &block)
        else
          super
        end
      end
      
      def respond_to_missing?(method, include_private = false)
        logger.respond_to?(method, include_private) || super
      end
    end
  end
end