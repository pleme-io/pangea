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
require 'pangea/cli/ui/banner'
require_relative 'application/options'
require_relative 'application/command_router'

module Pangea
  module CLI
    # Main CLI application entry point
    class Application < Commands::BaseCommand
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
