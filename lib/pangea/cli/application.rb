# frozen_string_literal: true

require 'tty-option'
require 'pangea/version'
require 'pangea/cli/commands/base_command'
require 'pangea/cli/commands/plan'
require 'pangea/cli/commands/apply' 
require 'pangea/cli/commands/destroy'
require 'pangea/cli/commands/inspect'
require 'pangea/cli/commands/agent'

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
      end
      
      argument :command do
        desc 'Command to execute'
        permit %w[plan apply destroy inspect agent]
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
        default ENV['PANGEA_NAMESPACE']
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
      
      def run
        parse(ARGV.dup)
        
        # Handle help flag
        if params[:help] || params[:command].nil?
          print help
          exit
        end
        
        # Handle version flag
        if params[:version]
          ui.say "pangea v#{Pangea::VERSION}", color: :bright_blue
          exit
        end
        
        # Enable debug mode
        ENV['DEBUG'] = '1' if params[:debug]
        
        # Route to appropriate command
        # Resolve namespace (CLI arg > env var > config default)
        namespace = resolve_namespace
        
        case params[:command]
        when 'plan'
          Commands::Plan.new.run(params[:file], namespace: namespace, template: params[:template])
        when 'apply'
          Commands::Apply.new.run(params[:file], namespace: namespace, template: params[:template], auto_approve: !params[:no_auto_approve])
        when 'destroy'
          Commands::Destroy.new.run(params[:file], namespace: namespace, template: params[:template], auto_approve: !params[:no_auto_approve])
        when 'inspect'
          # For inspect command, file is optional
          file = params[:file] unless params[:file] == 'inspect'
          Commands::Inspect.new.run(file, 
            type: params[:type] || 'all',
            template: params[:template],
            format: params[:format] || 'json',
            namespace: namespace
          )
        when 'agent'
          # For agent command, parse subcommand
          subcommand = params[:file]
          target = ARGV[2] # Get the actual target file
          Commands::Agent.new.run(subcommand, target,
            template: params[:template],
            namespace: namespace
          )
        else
          ui.error "Unknown command: #{params[:command]}"
          print help
          exit 1
        end
        
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
      
      def validate_file_argument!
        if params[:file].nil?
          ui.error "File argument is required for #{params[:command]} command"
          exit 1
        end
        
        unless File.exist?(params[:file])
          ui.error "File not found: #{params[:file]}"
          exit 1
        end
      end
      
      def resolve_namespace
        # Priority: CLI argument > environment variable > config default
        namespace = params[:namespace]
        
        if namespace.nil?
          # Use centralized configuration
          namespace = Pangea.config.default_namespace
        end
        
        if namespace.nil?
          ui.error "Namespace is required. Either:"
          ui.error "  - Use --namespace <name>"
          ui.error "  - Set PANGEA_NAMESPACE environment variable"
          ui.error "  - Set default_namespace in pangea.yml"
          exit 1
        end
        
        namespace
      end
    end
  end
end