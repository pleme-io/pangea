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
require 'json'
require 'fileutils'
require 'pangea/types'
require 'pangea/errors'
require 'pangea/logging'

module Pangea
  module Execution
    # Executes Terraform/OpenTofu commands
    class TerraformExecutor
      # Exit codes for terraform plan
      PLAN_EXIT_CODES = {
        0 => { success: true, changes: false, message: 'No changes required' },
        2 => { success: true, changes: true, message: 'Plan generated successfully' }
      }.freeze
      
      # Error patterns to extract from Terraform output
      ERROR_PATTERNS = [
        /Error: (.+?)\n/,
        /│ Error: (.+)/,
        /Failed to (.+)/
      ].freeze
      
      # Retryable error patterns
      RETRYABLE_ERROR_PATTERNS = [
        /timeout/i,
        /connection.*timed out/i,
        /connection.*refused/i,
        /rate limit/i,
        /throttl/i,
        /temporary failure/i,
        /network.*unreachable/i,
        /could not connect/i,
        /connection reset/i,
        /RequestLimitExceeded/,
        /ServiceUnavailable/
      ].freeze
      
      attr_reader :binary, :working_dir, :logger
      
      def initialize(working_dir:, binary: nil, logger: nil, max_retries: 3, retry_delay: 2)
        @working_dir = working_dir
        @binary = binary || Pangea.config.fetch(:terraform, :binary, default: 'tofu')
        @logger = logger
        @max_retries = max_retries
        @retry_delay = retry_delay
        
        ensure_working_directory!
      end
      
      # Initialize Terraform in the working directory
      def init(upgrade: false)
        with_retries do
          args = ['init', '-no-color', '-input=false']
          args << '-upgrade' if upgrade
          
          result = execute_command(args)
          
          # Raise if retryable to trigger retry logic
          if !result[:success] && result[:retryable]
            raise StandardError.new(result[:error] || result[:output])
          end
          
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
        args = ['plan', '-no-color', '-input=false', '-detailed-exitcode']
        args << '-destroy' if destroy
        args << "-out=#{out_file}" if out_file
        args << "-target=#{target}" if target
        
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
          args = build_args('apply', '-no-color', '-input=false') do |a|
            if plan_file
              a << plan_file
            else
              a << '-auto-approve' if auto_approve
              a << "-target=#{target}" if target
            end
          end
          
          result = execute_command(args) do |output|
            parse_apply_output(output)
          end
          
          # Raise if retryable to trigger retry logic
          if !result[:success] && result[:retryable]
            raise StandardError.new(result[:error] || result[:output])
          end
          
          result
        end
      end
      
      def parse_apply_output(output)
        return { success: false, message: 'Apply may have failed' } unless output.include?('Apply complete!')
        
        resources_match = output.match(/(\d+) added, (\d+) changed, (\d+) destroyed/)
        base_result = { success: true, message: 'Apply completed successfully' }
        
        return base_result unless resources_match
        
        base_result.merge(
          added: resources_match[1].to_i,
          changed: resources_match[2].to_i,
          destroyed: resources_match[3].to_i
        )
      end
      
      # Run terraform destroy
      def destroy(auto_approve: false, target: nil)
        with_retries do
          args = ['destroy', '-no-color', '-input=false']
          args << '-auto-approve' if auto_approve
          args << "-target=#{target}" if target
          
          result = execute_command(args) do |output|
            if output.include?('Destroy complete!')
              { success: true, message: 'Resources destroyed successfully' }
            else
              { success: false, message: 'Destroy may have failed' }
            end
          end
          
          # Raise if retryable to trigger retry logic
          if !result[:success] && result[:retryable]
            raise StandardError.new(result[:error] || result[:output])
          end
          
          result
        end
      end
      
      # Get terraform output
      def output(name: nil, json: true)
        args = ['output', '-no-color']
        args << '-json' if json
        args << name if name
        
        result = execute_command(args)
        
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
      
      # Get terraform state list
      def state_list
        args = ['state', 'list', '-no-color']
        
        result = execute_command(args)
        
        if result[:success]
          result[:resources] = result[:output].split("\n").reject(&:empty?)
        end
        
        result
      end
      
      # Validate terraform configuration
      def validate
        args = ['validate', '-no-color', '-json']
        
        result = execute_command(args)
        
        if result[:success]
          begin
            validation = JSON.parse(result[:output])
            result[:valid] = validation['valid']
            result[:errors] = validation['diagnostics'] || []
          rescue JSON::ParserError
            result[:success] = false
            result[:error] = 'Failed to parse validation output'
          end
        end
        
        result
      end
      
      # Check if terraform binary exists
      def binary_available?
        system("which #{@binary} > /dev/null 2>&1")
      end
      
      # Get terraform version
      def version
        result = execute_command(['version', '-json'])
        
        if result[:success]
          begin
            version_data = JSON.parse(result[:output])
            result[:version] = version_data['terraform_version']
          rescue JSON::ParserError
            # Try non-JSON format
            version_match = result[:output].match(/Terraform v(\d+\.\d+\.\d+)/)
            result[:version] = version_match[1] if version_match
          end
        end
        
        result
      end
      
      # Import a resource into terraform state
      def import_resource(resource_address, resource_id)
        with_retries do
          args = ['import', '-no-color', resource_address, resource_id]
          
          result = execute_command(args) do |output|
            if output.include?('Import successful!')
              { success: true, message: 'Resource imported successfully' }
            else
              { success: false, message: 'Import may have failed' }
            end
          end
          
          # Raise if retryable to trigger retry logic
          if !result[:success] && result[:retryable]
            raise StandardError.new(result[:error] || result[:output])
          end
          
          result
        end
      end
      alias import import_resource
      
      # Refresh terraform state
      def refresh
        args = ['refresh', '-no-color', '-input=false']
        
        result = execute_command(args) do |output|
          if output.include?('Refresh complete') || output.include?('No changes')
            { success: true, message: 'Refresh completed successfully' }
          else
            { success: false, message: 'Refresh may have failed' }
          end
        end
        
        result
      end
      
      # Format terraform configuration files
      def fmt(check: false, recursive: true)
        args = ['fmt']
        args << '-check' if check
        args << '-recursive' if recursive
        
        result = execute_command(args)
        
        if result[:success]
          formatted_files = result[:output].split("\n").reject(&:empty?)
          result[:formatted_files] = formatted_files
          result[:message] = check ? 'Format check passed' : "Formatted #{formatted_files.length} files"
        else
          result[:message] = 'Format failed'
        end
        
        result
      end
      
      # Execute command with retry logic for transient failures
      def execute_with_retry(method_name, *args, **kwargs)
        retries = 0
        last_error = nil
        
        loop do
          begin
            return send(method_name, *args, **kwargs)
          rescue StandardError => e
            last_error = e
            
            if retries < @max_retries && retryable_error?(e)
              retries += 1
              delay = @retry_delay ** retries  # Exponential backoff
              
              @logger&.warn "Retryable error occurred: #{e.message}"
              @logger&.info "Retrying in #{delay} seconds (attempt #{retries}/#{@max_retries})..."
              
              sleep(delay)
              next
            else
              # Non-retryable error or max retries exceeded
              raise Errors::PangeaError.new(
                "Operation failed after #{retries} retries",
                context: { 
                  method: method_name, 
                  retries: retries,
                  last_error: e.message
                },
                cause: e
              )
            end
          end
        end
      end
      
      private
      
      # Wrapper for operations that should be retried on transient failures
      def with_retries
        retries = 0
        
        begin
          yield
        rescue StandardError => e
          if retries < @max_retries && (retryable_error?(e) || retryable_output?(e.message, ''))
            retries += 1
            delay = @retry_delay ** retries
            
            @logger&.warn "Retryable error: #{e.message}"
            @logger&.info "Retry #{retries}/#{@max_retries} in #{delay}s..."
            
            sleep(delay)
            retry
          else
            raise
          end
        end
      end
      
      # Check if an error is retryable based on patterns
      def retryable_error?(error)
        error_message = error.message.to_s
        
        RETRYABLE_ERROR_PATTERNS.any? do |pattern|
          error_message.match?(pattern)
        end
      end
      
      # Check if command output indicates a retryable error
      def retryable_output?(output, error)
        combined_output = "#{output} #{error}"
        
        RETRYABLE_ERROR_PATTERNS.any? do |pattern|
          combined_output.match?(pattern)
        end
      end
      
      def ensure_working_directory!
        FileUtils.mkdir_p(@working_dir) unless Dir.exist?(@working_dir)
      end
      
      def execute_command(args, capture_exit_code: false)
        cmd = [@binary] + args
        
        @logger&.debug "Executing: #{cmd.join(' ')}"
        
        output = []
        error = []
        exit_code = nil
        
        # Execute command and capture output
        Open3.popen3(*cmd, chdir: @working_dir) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          
          # Read output streams
          stdout.each_line { |line| output << line; @logger&.debug(line.chomp) }
          stderr.each_line { |line| error << line; @logger&.debug(line.chomp) }
          
          exit_code = wait_thr.value.exitstatus
        end
        
        result = {
          success: exit_code == 0 || (capture_exit_code && exit_code == 2),
          output: output.join,
          error: error.join,
          exit_code: exit_code
        }
        
        # Check if the error is retryable
        if !result[:success] && retryable_output?(result[:output], result[:error])
          result[:retryable] = true
        end
        
        # Process output with block if given
        if block_given?
          processed = yield(result[:output], exit_code)
          result.merge!(processed) if processed.is_a?(Hash)
        end
        
        result
      rescue StandardError => e
        {
          success: false,
          error: e.message,
          output: '',
          exit_code: -1
        }
      end
      
      def parse_plan_output(output)
        changes = {
          create: [],
          update: [],
          delete: [],
          replace: []
        }
        
        output.lines.each do |line|
          case line
          when /^\s*\+\s+(.+)$/
            changes[:create] << $1.strip
          when /^\s*~\s+(.+)$/
            changes[:update] << $1.strip
          when /^\s*-\s+(.+)$/
            changes[:delete] << $1.strip
          when /^\s*\+\/\-\s+(.+)$/
            changes[:replace] << $1.strip
          end
        end
        
        changes
      end
      
      def extract_terraform_error(output)
        return output if output.nil? || output.empty?
        
        # Try to match specific error patterns first
        ERROR_PATTERNS.each do |pattern|
          match = output.match(pattern)
          return match[1] if match
        end
        
        # Fallback to line-based error extraction
        error_lines = output.lines.select do |line|
          line.include?('Error:') || 
          line.include?('Failed to') ||
          line.include?('Could not') ||
          line.include?('Unable to') ||
          line.include?('Invalid') ||
          line.include?('Missing')
        end
        
        if error_lines.any?
          error_lines.join("\n").strip
        else
          # Return the last few meaningful lines if no specific error found
          output.lines.reject(&:empty?).last(5).join("\n").strip
        end
      end
      
      # Build command arguments with block for conditional additions
      def build_args(*base_args)
        args = base_args.dup
        yield(args) if block_given?
        args
      end
      
      def debug_enabled?
        @logger || ENV['DEBUG']
      end
      
      def debug_log(message)
        if @logger
          @logger.call(message)
        else
          puts "[DEBUG] #{message}"
        end
      end
    end
  end
end