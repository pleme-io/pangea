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


require 'tty-spinner'
require 'pastel'

module Pangea
  module CLI
    module UI
      # Enhanced Spinner UI component for showing progress
      class Spinner
        def initialize(message = nil, options = {})
          @pastel = Pastel.new
          format = options.fetch(:format, :dots)
          
          # Enhanced spinner with beautiful formatting
          spinner_format = "[:spinner] #{@pastel.white(message)}"
          
          @spinner = TTY::Spinner.new(
            spinner_format,
            format: format,
            hide_cursor: true,
            success_mark: @pastel.bright_green('✅'),
            error_mark: @pastel.bright_red('❌'),
            clear: options.fetch(:clear, false),
            interval: options.fetch(:interval, 10)
          )
          
          @start_time = nil
        end
        
        def start
          @start_time = Time.now
          @spinner.start
        end
        
        def stop
          @spinner.stop
        end
        
        def success(message = nil)
          if message && @start_time
            duration = Time.now - @start_time
            formatted_message = "#{@pastel.bright_green(message)} #{@pastel.bright_black("(#{format_duration(duration))})")}"
            @spinner.success(formatted_message)
          else
            @spinner.success(message)
          end
        end
        
        def error(message = nil)
          formatted_message = message ? @pastel.bright_red(message) : nil
          @spinner.error(formatted_message)
        end
        
        def warning(message = nil)
          formatted_message = message ? @pastel.bright_yellow(message) : nil
          @spinner.success("⚠️  #{formatted_message}")
        end
        
        def update(message)
          @spinner.update(title: "[:spinner] #{@pastel.white(message)}")
        end
        
        def spin
          start
          result = yield
          success
          result
        rescue => e
          error(e.message)
          raise e
        ensure
          stop
        end
        
        # Multi-stage spinner for complex operations
        def self.multi_stage(stages, &block)
          total_stages = stages.length
          current_stage = 0
          
          stages.each do |stage_name|
            current_stage += 1
            stage_spinner = new("#{stage_name} (#{current_stage}/#{total_stages})")
            
            begin
              stage_spinner.start
              yield(stage_spinner, stage_name)
              stage_spinner.success("#{stage_name} complete")
            rescue => e
              stage_spinner.error("#{stage_name} failed")
              raise e
            end
          end
        end
        
        # Specialized spinners for common operations
        def self.compilation(message = "Compiling templates")
          new(message, format: :bouncing_ball)
        end
        
        def self.terraform_operation(operation)
          message = case operation
                   when :init then "Initializing Terraform"
                   when :plan then "Planning infrastructure"
                   when :apply then "Applying changes" 
                   when :destroy then "Destroying resources"
                   when :validate then "Validating configuration"
                   when :refresh then "Refreshing state"
                   else "Running Terraform"
                   end
          
          new(message, format: :arrow)
        end
        
        def self.network_operation(message = "Network operation")
          new(message, format: :pulse)
        end
        
        def self.file_operation(message = "File operation")
          new(message, format: :classic)
        end
        
        private
        
        def format_duration(seconds)
          if seconds < 1
            "#{(seconds * 1000).round}ms"
          elsif seconds < 60
            "#{seconds.round(1)}s"
          else
            minutes = (seconds / 60).floor
            remaining_seconds = (seconds % 60).round
            "#{minutes}m #{remaining_seconds}s"
          end
        end
      end
    end
  end
end