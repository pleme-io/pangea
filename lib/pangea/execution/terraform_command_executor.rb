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

require 'open3'

module Pangea
  module Execution
    # Handles command execution logic for Terraform
    module TerraformCommandExecutor
      private
      
      def execute_command(args, capture_exit_code: false)
        cmd = [@binary] + args
        command_str = cmd.join(' ')
        
        @logger.debug "Executing Terraform command", 
                     command: command_str,
                     working_dir: @working_dir
        
        output, error, exit_code = capture_command_output(cmd)
        
        result = build_command_result(output, error, exit_code, capture_exit_code)
        
        # Process output with block if given
        if block_given?
          processed = yield(result[:output], exit_code)
          result.merge!(processed) if processed.is_a?(Hash)
        end
        
        result
      rescue StandardError => e
        { success: false, error: e.message, output: '', exit_code: -1 }
      end
      
      def capture_command_output(cmd)
        output = []
        error = []
        exit_code = nil
        
        Open3.popen3(*cmd, chdir: @working_dir) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          
          # Read output streams
          stdout.each_line do |line| 
            output << line
            @logger.debug "Terraform stdout", line: line.chomp if ENV['PANGEA_TERRAFORM_OUTPUT']
          end
          
          stderr.each_line do |line|
            error << line
            @logger.debug "Terraform stderr", line: line.chomp if ENV['PANGEA_TERRAFORM_OUTPUT']
          end
          
          exit_code = wait_thr.value.exitstatus
        end
        
        [output.join, error.join, exit_code]
      end
      
      def build_command_result(output, error, exit_code, capture_exit_code)
        result = {
          success: exit_code == 0 || (capture_exit_code && exit_code == 2),
          output: output,
          error: error,
          exit_code: exit_code
        }
        
        # Check if the error is retryable
        if !result[:success] && retryable_output?(output, error)
          result[:retryable] = true
        end
        
        # Log command result
        @logger.info "Terraform command completed",
                    success: result[:success],
                    exit_code: exit_code,
                    output_lines: output.lines.size,
                    error_lines: error.lines.size,
                    retryable: result[:retryable] || false
        
        result
      end
      
      def handle_retryable_result(result)
        if !result[:success] && result[:retryable]
          raise StandardError.new(result[:error] || result[:output])
        end
      end
    end
  end
end