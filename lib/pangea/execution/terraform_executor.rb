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

module Pangea
  module Execution
    # Executes Terraform/OpenTofu commands
    class TerraformExecutor
      attr_reader :binary, :working_dir, :logger
      
      def initialize(working_dir:, binary: nil, logger: nil)
        @working_dir = working_dir
        @binary = binary || Pangea.config.fetch(:terraform, :binary, default: 'tofu')
        @logger = logger
        
        ensure_working_directory!
      end
      
      # Initialize Terraform in the working directory
      def init(upgrade: false)
        args = ['init', '-no-color', '-input=false']
        args << '-upgrade' if upgrade
        
        execute_command(args) do |output|
          # Parse init output for important information
          if output.include?('Terraform has been successfully initialized!')
            { success: true, message: 'Initialization complete' }
          else
            { success: false, message: 'Initialization may have failed' }
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
          case exit_code
          when 0
            { success: true, changes: false, message: 'No changes required' }
          when 2
            { success: true, changes: true, message: 'Plan generated successfully' }
          else
            { success: false, message: 'Plan failed' }
          end
        end
        
        # Parse plan output for resource changes
        result[:resource_changes] = parse_plan_output(result[:output]) if result[:success]
        result
      end
      
      # Run terraform apply
      def apply(plan_file: nil, auto_approve: false, target: nil)
        args = ['apply', '-no-color', '-input=false']
        
        if plan_file
          args << plan_file
        else
          args << '-auto-approve' if auto_approve
          args << "-target=#{target}" if target
        end
        
        execute_command(args) do |output|
          if output.include?('Apply complete!')
            # Extract resource counts
            resources_match = output.match(/(\d+) added, (\d+) changed, (\d+) destroyed/)
            if resources_match
              {
                success: true,
                message: 'Apply completed successfully',
                added: resources_match[1].to_i,
                changed: resources_match[2].to_i,
                destroyed: resources_match[3].to_i
              }
            else
              { success: true, message: 'Apply completed successfully' }
            end
          else
            { success: false, message: 'Apply may have failed' }
          end
        end
      end
      
      # Run terraform destroy
      def destroy(auto_approve: false, target: nil)
        args = ['destroy', '-no-color', '-input=false']
        args << '-auto-approve' if auto_approve
        args << "-target=#{target}" if target
        
        execute_command(args) do |output|
          if output.include?('Destroy complete!')
            { success: true, message: 'Resources destroyed successfully' }
          else
            { success: false, message: 'Destroy may have failed' }
          end
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
      
      private
      
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
    end
  end
end