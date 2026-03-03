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

module Pangea
  module Execution
    # Builds Terraform commands with proper arguments
    module TerraformCommandBuilder
      # Build init command arguments
      def build_init_args(upgrade: false)
        args = ['init', '-no-color', '-input=false']
        args << '-upgrade' if upgrade
        args
      end
      
      # Build plan command arguments
      def build_plan_args(out_file: nil, destroy: false, target: nil)
        args = ['plan', '-no-color', '-input=false', '-detailed-exitcode']
        args << '-destroy' if destroy
        args << "-out=#{out_file}" if out_file
        args << "-target=#{target}" if target
        args
      end
      
      # Build apply command arguments
      def build_apply_args(plan_file: nil, auto_approve: false, target: nil)
        build_args('apply', '-no-color', '-input=false') do |a|
          if plan_file
            a << plan_file
          else
            a << '-auto-approve' if auto_approve
            a << "-target=#{target}" if target
          end
        end
      end
      
      # Build destroy command arguments
      def build_destroy_args(auto_approve: false, target: nil)
        args = ['destroy', '-no-color', '-input=false']
        args << '-auto-approve' if auto_approve
        args << "-target=#{target}" if target
        args
      end
      
      # Build output command arguments
      def build_output_args(name: nil, json: true)
        args = ['output', '-no-color']
        args << '-json' if json
        args << name if name
        args
      end
      
      # Build import command arguments
      def build_import_args(resource_address, resource_id)
        ['import', '-no-color', resource_address, resource_id]
      end
      
      # Build format command arguments
      def build_fmt_args(check: false, recursive: true)
        args = ['fmt']
        args << '-check' if check
        args << '-recursive' if recursive
        args
      end
      
      private
      
      # Build command arguments with block for conditional additions
      def build_args(*base_args)
        args = base_args.dup
        yield(args) if block_given?
        args
      end
    end
  end
end