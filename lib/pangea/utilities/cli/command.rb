# lib/pangea/utilities/cli/command.rb
require 'thor'

module Pangea
  module Utilities
    module CLI
      class Command < Thor::Group
        include Thor::Actions
        
        def self.banner
          "pangea #{command_name} [OPTIONS]"
        end
        
        def self.command_name
          name.split('::').last.downcase.sub('command', '')
        end
        
        protected
        
        def load_configuration
          config_file = options[:config] || 'pangea.yaml'
          
          unless File.exist?(config_file)
            error "Configuration file not found: #{config_file}"
            exit 1
          end
          
          YAML.load_file(config_file)
        rescue => e
          error "Failed to load configuration: #{e.message}"
          exit 1
        end
        
        def get_namespace
          options[:namespace] || config['default_namespace'] || 'default'
        end
        
        def get_template_names
          if options[:all]
            discover_all_templates
          elsif options[:template]
            [options[:template]]
          else
            error "Specify --template NAME or --all"
            exit 1
          end
        end
        
        def discover_all_templates
          namespace = get_namespace
          workspace_dir = File.expand_path("~/.pangea/workspaces/#{namespace}")
          
          return [] unless Dir.exist?(workspace_dir)
          
          Dir.entries(workspace_dir).select do |entry|
            File.directory?(File.join(workspace_dir, entry)) && entry !~ /^\./
          end
        end
        
        def success(message)
          say message, :green
        end
        
        def error(message)
          say message, :red
        end
        
        def warning(message)
          say message, :yellow
        end
        
        def info(message)
          say message, :cyan
        end
        
        private
        
        def config
          @config ||= load_configuration
        end
      end
    end
  end
end