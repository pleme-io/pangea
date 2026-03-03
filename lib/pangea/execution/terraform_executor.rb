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
require 'fileutils'
require 'pangea/types'
require 'pangea/errors'
require 'pangea/logging'
require 'pangea/execution/terraform_retry'
require 'pangea/execution/terraform_output_parser'
require 'pangea/execution/terraform_command_builder'
require 'pangea/execution/terraform_command_executor'
require 'pangea/execution/terraform_operations'

module Pangea
  module Execution
    # Executes Terraform/OpenTofu commands
    class TerraformExecutor
      include TerraformRetry
      include TerraformOutputParser
      include TerraformCommandBuilder
      include TerraformCommandExecutor
      include TerraformOperations
      
      # Exit codes for terraform plan
      PLAN_EXIT_CODES = {
        0 => { success: true, changes: false, message: 'No changes required' },
        2 => { success: true, changes: true, message: 'Plan generated successfully' }
      }.freeze
      
      attr_reader :binary, :working_dir, :logger
      
      def initialize(working_dir:, binary: nil, logger: nil, max_retries: 3, retry_delay: 2)
        @working_dir = working_dir
        @binary = binary || Pangea.config.fetch(:terraform, :binary, default: 'tofu')
        @max_retries = max_retries
        @retry_delay = retry_delay
        
        # Use structured logger if no logger provided
        @logger = logger || Logging.logger.child(
          component: 'TerraformExecutor',
          working_dir: working_dir,
          binary: @binary
        )
        
        ensure_working_directory!
      end
      
      # Initialize Terraform in the working directory
      def init(upgrade: false, stream_output: false)
        with_retries do
          result = execute_command(build_init_args(upgrade: upgrade), stream_output: stream_output)
          handle_retryable_result(result)

          if result[:success]
            result.merge(message: 'Initialization complete')
          else
            error_details = result[:error].empty? ? result[:output] : result[:error]
            result.merge(
              message: 'Initialization failed',
              error: extract_terraform_error(error_details)
            )
          end
        end
      end
      
      # Run terraform plan
      def plan(out_file: nil, destroy: false, target: nil)
        args = build_plan_args(out_file: out_file, destroy: destroy, target: target)
        
        result = execute_command(args, capture_exit_code: true) do |output, exit_code|
          PLAN_EXIT_CODES[exit_code] || { success: false, message: 'Plan failed' }
        end
        
        # Parse plan output for resource changes
        result[:resource_changes] = parse_plan_output(result[:output]) if result[:success]
        result
      end
      
      # Run terraform apply
      def apply(plan_file: nil, auto_approve: false, target: nil)
        with_retries do
          args = build_apply_args(plan_file: plan_file, auto_approve: auto_approve, target: target)
          result = execute_command(args) { |output| parse_apply_output(output) }
          handle_retryable_result(result)
          result
        end
      end
      
      # Run terraform destroy
      def destroy(auto_approve: false, target: nil)
        with_retries do
          result = execute_command(build_destroy_args(auto_approve: auto_approve, target: target)) do |output|
            if output.include?('Destroy complete!')
              { success: true, message: 'Resources destroyed successfully' }
            else
              { success: false, message: 'Destroy may have failed' }
            end
          end
          handle_retryable_result(result)
          result
        end
      end
      
      # Get terraform output
      def output(name: nil, json: true)
        result = execute_command(build_output_args(name: name, json: json))
        
        if json && result[:success]
          begin
            result[:data] = JSON.parse(result[:output])
          rescue JSON::ParserError
            result[:success] = false
            result[:error] = 'Failed to parse JSON output'
          end
        end
        
        result
      end
      
      private
      
      def ensure_working_directory!
        FileUtils.mkdir_p(@working_dir) unless Dir.exist?(@working_dir)
      end
    end
  end
end