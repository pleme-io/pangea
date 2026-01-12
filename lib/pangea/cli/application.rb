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

require 'tty-option'
require 'pangea/version'
require 'pangea/cli/commands/base_command'
require 'pangea/cli/commands/init'
require 'pangea/cli/commands/plan'
require 'pangea/cli/commands/apply'
require 'pangea/cli/commands/destroy'
require 'pangea/cli/commands/inspect'
require 'pangea/cli/commands/agent'
require 'pangea/cli/commands/import'
require 'pangea/cli/commands/sync'
require 'pangea/cli/ui/banner'
require_relative 'application/options'
require_relative 'application/command_router'

module Pangea
  module CLI
    # Main CLI application entry point
    class Application < Commands::BaseCommand
      usage do
        program 'pangea'

        desc 'Beautiful infrastructure management with OpenTofu'

        example 'Plan infrastructure changes',
                '  $ pangea plan infrastructure.rb --namespace production'

        example 'Apply infrastructure changes',
                '  $ pangea apply infrastructure.rb'

        example 'Plan specific template',
                '  $ pangea plan infrastructure.rb --template web_server'

        example 'Apply to specific namespace',
                '  $ pangea apply infrastructure.rb --namespace production'

        example 'Destroy with confirmation prompt',
                '  $ pangea destroy infrastructure.rb --no-auto-approve'

        example 'Import existing resources',
                '  $ pangea import infrastructure.rb --namespace production --resource aws_route53_zone.main --id Z1234567890ABC'
      end

      argument :command do
        desc 'Command to execute'
        permit %w[init plan apply destroy inspect agent import sync]
      end

      argument :file do
        desc 'Infrastructure file to process'
        required
        validate ->(f) { File.exist?(f) }
      end

      flag :help do
        short '-h'
        long '--help'
        desc 'Print help information'
      end

      flag :version do
        short '-v'
        long '--version'
        desc 'Print version information'
      end

      option :namespace do
        short '-n'
        long '--namespace string'
        desc 'Target namespace (uses default_namespace from config if not specified)'
        default ENV.fetch('PANGEA_NAMESPACE', nil)
      end

      option :debug do
        long '--debug'
        desc 'Enable debug output'
      end

      option :no_auto_approve do
        long '--no-auto-approve'
        desc 'Require explicit confirmation (default is auto-approve)'
      end

      option :template do
        short '-t'
        long '--template string'
        desc 'Target specific template within file'
      end

      option :show_compiled do
        long '--show-compiled'
        desc 'Show compiled Terraform JSON output (plan command only)'
      end

      option :json do
        long '--json'
        desc 'Output results in JSON format (agent-friendly)'
      end

      option :type do
        long '--type string'
        desc 'Type for inspect command (all|templates|resources|architectures|components|namespaces|config|state|render)'
        default 'all'
      end

      option :format do
        long '--format string'
        desc 'Output format (json|yaml|text)'
        default 'json'
      end

      option :resource do
        long '--resource string'
        desc 'Resource address for import (e.g., aws_route53_zone.staging_zone)'
      end

      option :id do
        long '--id string'
        desc 'Resource ID to import (e.g., Z1234567890ABC)'
      end
      usage do
        program 'pangea'

        desc 'Beautiful infrastructure management with OpenTofu'

        example 'Plan infrastructure changes',
                '  $ pangea plan infrastructure.rb --namespace production'

        example 'Apply infrastructure changes',
                '  $ pangea apply infrastructure.rb'

        example 'Plan specific template',
                '  $ pangea plan infrastructure.rb --template web_server'

        example 'Apply to specific namespace',
                '  $ pangea apply infrastructure.rb --namespace production'

        example 'Destroy with confirmation prompt',
                '  $ pangea destroy infrastructure.rb --no-auto-approve'

        example 'Import existing resources',
                '  $ pangea import infrastructure.rb --namespace production --resource aws_route53_zone.main --id Z1234567890ABC'
      end

      argument :command do
        desc 'Command to execute'
        permit %w[init plan apply destroy inspect agent import]
      end

      argument :file do
        desc 'Infrastructure file to process'
        required
        validate ->(f) { File.exist?(f) }
      end

      flag :help do
        short '-h'
        long '--help'
        desc 'Print help information'
      end

      flag :version do
        short '-v'
        long '--version'
        desc 'Print version information'
      end

      option :namespace do
        short '-n'
        long '--namespace string'
        desc 'Target namespace (uses default_namespace from config if not specified)'
        default ENV.fetch('PANGEA_NAMESPACE', nil)
      end

      option :debug do
        long '--debug'
        desc 'Enable debug output'
      end

      option :no_auto_approve do
        long '--no-auto-approve'
        desc 'Require explicit confirmation (default is auto-approve)'
      end

      option :template do
        short '-t'
        long '--template string'
        desc 'Target specific template within file'
      end

      option :show_compiled do
        long '--show-compiled'
        desc 'Show compiled Terraform JSON output (plan command only)'
      end

      option :json do
        long '--json'
        desc 'Output results in JSON format (agent-friendly)'
      end

      option :type do
        long '--type string'
        desc 'Type for inspect command (all|templates|resources|architectures|components|namespaces|config|state|render)'
        default 'all'
      end

      option :format do
        long '--format string'
        desc 'Output format (json|yaml|text)'
        default 'json'
      end

      option :resource do
        long '--resource string'
        desc 'Resource address for import (e.g., aws_route53_zone.staging_zone)'
      end

      option :id do
        long '--id string'
        desc 'Resource ID to import (e.g., Z1234567890ABC)'
      end
      include Application::Options
      include Application::CommandRouter

      def run
        @banner = UI::Banner.new

        handle_version_flag
        parse(ARGV.dup)
        handle_help_flag

        # Show header for commands
        @banner.header(params[:command]) if params[:command]

        # Enable debug mode
        ENV['DEBUG'] = '1' if params[:debug]

        # Route to appropriate command
        namespace = resolve_namespace

        case params[:command]
        when 'init'
          Commands::Init.new.run(params[:file], namespace: namespace, template: params[:template])
        when 'plan'
          Commands::Plan.new.run(params[:file], namespace: namespace, template: params[:template],
                                                show_compiled: params[:show_compiled])
        when 'apply'
          Commands::Apply.new.run(params[:file], namespace: namespace, template: params[:template],
                                                 auto_approve: !params[:no_auto_approve])
        when 'destroy'
          Commands::Destroy.new.run(params[:file], namespace: namespace, template: params[:template],
                                                   auto_approve: !params[:no_auto_approve])
        when 'inspect'
          # For inspect command, file is optional
          file = params[:file] unless params[:file] == 'inspect'
          Commands::Inspect.new.run(
            file,
            type: params[:type] || 'all',
            template: params[:template],
            format: params[:format] || 'json',
            namespace: namespace
          )

        when 'agent'
          # For agent command, parse subcommand
          subcommand = params[:file]
          target = ARGV[2] # Get the actual target file
          Commands::Agent.new.run(
            subcommand, target,
            template: params[:template],
            namespace: namespace
          )

        when 'import'
          Commands::Import.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template],
            resource: params[:resource],
            id: params[:id]
          )
        when 'sync'
          Commands::Sync.new.run(params[:file], namespace: namespace, template: params[:template])
        else
          ui.error "Unknown command: #{params[:command]}"
          print help
          exit 1
        end

        case params[:command]
        when 'init'
          Commands::Init.new.run(params[:file], namespace: namespace, template: params[:template])
        when 'plan'
          Commands::Plan.new.run(params[:file], namespace: namespace, template: params[:template],
                                                show_compiled: params[:show_compiled])
        when 'apply'
          Commands::Apply.new.run(params[:file], namespace: namespace, template: params[:template],
                                                 auto_approve: !params[:no_auto_approve])
        when 'destroy'
          Commands::Destroy.new.run(params[:file], namespace: namespace, template: params[:template],
                                                   auto_approve: !params[:no_auto_approve])
        when 'inspect'
          # For inspect command, file is optional
          file = params[:file] unless params[:file] == 'inspect'
          Commands::Inspect.new.run(
            file,
            type: params[:type] || 'all',
            template: params[:template],
            format: params[:format] || 'json',
            namespace: namespace
          )

        when 'agent'
          # For agent command, parse subcommand
          subcommand = params[:file]
          target = ARGV[2] # Get the actual target file
          Commands::Agent.new.run(
            subcommand, target,
            template: params[:template],
            namespace: namespace
          )

        when 'import'
          Commands::Import.new.run(
            params[:file],
            namespace: namespace,
            template: params[:template],
            resource: params[:resource],
            id: params[:id]
          )
        else
          ui.error "Unknown command: #{params[:command]}"
          print help
          exit 1
        end

        route_command(params[:command], namespace)
      rescue TTY::Option::InvalidParameter => e
        ui.error e.message
        print help
        exit 1
      rescue StandardError => e
        ui.error "Error: #{e.message}"
        ui.say e.backtrace.join("\n"), color: :red if params[:debug]
        exit 1
      end

      private

      def handle_version_flag
        return unless ARGV.include?('--version') || ARGV.include?('-v')

        puts @banner.welcome
        exit
      end

      def handle_help_flag
        return unless params[:help] || params[:command].nil?

        puts @banner.welcome
        puts "\n"
        print help
        exit
      end

      def validate_file_argument!
        if params[:file].nil?
          ui.error "File argument is required for #{params[:command]} command"
          exit 1
        end

        return if File.exist?(params[:file])

        ui.error "File not found: #{params[:file]}"
        exit 1
      end

      def resolve_namespace
        # Priority: CLI argument > environment variable > config default
        namespace = params[:namespace]
        namespace ||= Pangea.config.default_namespace

        return namespace if namespace

        ui.error 'Namespace is required. Either:'
        ui.error '  - Use --namespace <name>'
        ui.error '  - Set PANGEA_NAMESPACE environment variable'
        ui.error '  - Set default_namespace in pangea.yml'
        exit 1
      end
    end
  end
end
