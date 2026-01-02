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
  module CLI
    module Application
      # Routes CLI commands to appropriate handler classes
      module CommandRouter
        def route_command(command, namespace)
          case command
          when 'init'
            run_init(namespace)
          when 'plan'
            run_plan(namespace)
          when 'apply'
            run_apply(namespace)
          when 'destroy'
            run_destroy(namespace)
          when 'inspect'
            run_inspect(namespace)
          when 'agent'
            run_agent(namespace)
          when 'import'
            run_import(namespace)
          else
            handle_unknown_command(command)
          end
        end

        private

        def run_init(namespace)
          Commands::Init.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template]
          )
        end

        def run_plan(namespace)
          Commands::Plan.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template],
            show_compiled: params[:show_compiled]
          )
        end

        def run_apply(namespace)
          Commands::Apply.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template],
            auto_approve: !params[:no_auto_approve]
          )
        end

        def run_destroy(namespace)
          Commands::Destroy.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template],
            auto_approve: !params[:no_auto_approve]
          )
        end

        def run_inspect(namespace)
          # For inspect command, file is optional
          file = params[:file] unless params[:file] == 'inspect'
          Commands::Inspect.new.run(
            file,
            type: params[:type] || 'all',
            template: params[:template],
            format: params[:format] || 'json',
            namespace: namespace
          )
        end

        def run_agent(namespace)
          # For agent command, parse subcommand
          subcommand = params[:file]
          target = ARGV[2] # Get the actual target file
          Commands::Agent.new.run(
            subcommand, target,
            template: params[:template],
            namespace: namespace
          )
        end

        def run_import(namespace)
          Commands::Import.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template],
            resource: params[:resource],
            id: params[:id]
          )
        end

        def handle_unknown_command(command)
          ui.error "Unknown command: #{command}"
          print help
          exit 1
        end
      end
    end
  end
end
