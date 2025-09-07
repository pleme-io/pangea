# lib/pangea/utilities/drift/detector.rb
require 'open3'
require 'json'

module Pangea
  module Utilities
    module Drift
      class Detector
        def detect_drift(template_name, namespace = nil)
          workspace_path = get_workspace_path(template_name, namespace)
          
          unless Dir.exist?(workspace_path)
            return Report.new(template_name, :error, { error: "Workspace not found" })
          end
          
          Dir.chdir(workspace_path) do
            # Initialize if needed
            init_result = run_terraform_init
            return init_result if init_result.error?
            
            # Run plan with detailed exitcode
            plan_result = run_terraform_plan
            
            case plan_result[:exit_code]
            when 0
              Report.new(template_name, :no_changes)
            when 1
              Report.new(template_name, :error, { error: plan_result[:stderr] })
            when 2
              parse_plan_output(template_name, plan_result[:stdout])
            else
              Report.new(template_name, :error, { error: "Unknown exit code: #{plan_result[:exit_code]}" })
            end
          end
        rescue => e
          Report.new(template_name, :error, { error: e.message })
        end
        
        def detect_all_drift(namespace = nil)
          templates = discover_templates(namespace)
          
          templates.map do |template|
            detect_drift(template, namespace)
          end
        end
        
        private
        
        def get_workspace_path(template_name, namespace)
          namespace ||= 'default'
          File.expand_path("~/.pangea/workspaces/#{namespace}/#{template_name}")
        end
        
        def run_terraform_init
          stdout, stderr, status = Open3.capture3('terraform init -no-color')
          
          if status.success?
            Report.new('init', :success)
          else
            Report.new('init', :error, { error: stderr })
          end
        end
        
        def run_terraform_plan
          stdout, stderr, status = Open3.capture3('terraform plan -no-color -detailed-exitcode')
          
          {
            stdout: stdout,
            stderr: stderr,
            exit_code: status.exitstatus
          }
        end
        
        def parse_plan_output(template_name, output)
          changes = {
            resources_to_add: [],
            resources_to_change: [],
            resources_to_destroy: []
          }
          
          output.lines.each do |line|
            case line
            when /^\s*\+\s+(.+)/
              changes[:resources_to_add] << $1.strip
            when /^\s*\~\s+(.+)/
              changes[:resources_to_change] << $1.strip
            when /^\s*\-\s+(.+)/
              changes[:resources_to_destroy] << $1.strip
            end
          end
          
          Report.new(template_name, :drift_detected, changes)
        end
        
        def discover_templates(namespace)
          namespace ||= 'default'
          workspace_dir = File.expand_path("~/.pangea/workspaces/#{namespace}")
          
          return [] unless Dir.exist?(workspace_dir)
          
          Dir.entries(workspace_dir).select do |entry|
            File.directory?(File.join(workspace_dir, entry)) && entry !~ /^\./
          end
        end
      end
    end
  end
end