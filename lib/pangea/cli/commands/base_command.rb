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
require 'pangea/cli/ui/logger'
require 'pangea/cli/ui/spinner'
require 'pangea/cli/ui/table'

module Pangea
  module CLI
    module Commands
      # Base command class with shared functionality
      class BaseCommand
        include TTY::Option
        
        # UI components
        def ui
          @ui ||= UI::Logger.new
        end
        
        def spinner
          @spinner ||= UI::Spinner
        end
        
        def table
          UI::Table
        end
        
        
        # Configuration access
        def config
          @config ||= begin
            require 'tty-config'
            cfg = TTY::Config.new
            cfg.filename = 'pangea'
            cfg.append_path Dir.pwd
            cfg.append_path File.join(Dir.home, '.config', 'pangea')
            cfg.append_path '/etc/pangea'
            cfg.env_prefix = 'PANGEA'
            cfg.read
            cfg
          rescue TTY::Config::ReadError
            ui.warn "No configuration file found, using defaults"
            TTY::Config.new
          end
        end
        
        # Check if running in CI/CD environment
        def ci_environment?
          ENV['CI'] || ENV['CONTINUOUS_INTEGRATION'] || ENV['GITHUB_ACTIONS'] || ENV['GITLAB_CI']
        end
        
        
        # Load and validate namespace configuration
        def load_namespace(name)
          return nil if name.nil?
          
          # Use the proper Configuration API instead of direct config access
          namespace_entity = Pangea.config.namespace(name)
          
          if namespace_entity.nil?
            ui.error "Namespace '#{name}' not found in configuration"
            available_names = Pangea.config.namespaces.map(&:name)
            ui.say "Available namespaces: #{available_names.join(', ')}"
            exit 1
          end
          
          namespace_entity
        rescue Dry::Struct::Error => e
          ui.error "Invalid namespace configuration: #{e.message}"
          exit 1
        end
        
        # Display summary table
        def display_summary(title, data)
          return if data.empty?
          
          ui.say "\n#{title}", color: :bright_cyan
          table.render(data)
        end
        
        # Execute with spinner
        def with_spinner(message, done: 'Done', error: 'Failed')
          spin_instance = UI::Spinner.new(message)
          spin_instance.start
          result = yield
          spin_instance.success(done)
          result
        rescue StandardError => e
          spin_instance.error(error)
          raise e
        end
        
        # Measure execution time
        def measure_time
          start_time = Time.now
          result = yield
          elapsed = Time.now - start_time
          
          ui.say "Completed in #{format_duration(elapsed)}", color: :bright_black
          result
        end
        
        private
        
        def format_duration(seconds)
          if seconds < 60
            "#{seconds.round(2)}s"
          else
            minutes = (seconds / 60).floor
            seconds = (seconds % 60).round
            "#{minutes}m #{seconds}s"
          end
        end
      end
    end
  end
end