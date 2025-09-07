# lib/pangea/utilities/cli/commands/drift_command.rb
require_relative '../command'

module Pangea
  module Utilities
    module CLI
      module Commands
        class DriftCommand < Command
          desc "Detect and manage infrastructure drift"
          
          class_option :namespace, type: :string, aliases: '-n',
                       desc: "Namespace to use"
          
          desc "detect", "Detect drift in templates"
          option :template, type: :string,
                 desc: "Template to check"
          option :all, type: :boolean,
                 desc: "Check all templates"
          def detect
            templates = get_template_names
            detector = Drift::Detector.new
            
            reports = templates.map do |template|
              info "Checking #{template}..."
              detector.detect_drift(template, get_namespace)
            end
            
            # Summary
            say ""
            info "Drift Detection Summary:"
            info "=" * 50
            
            reports.each do |report|
              if report.drift_detected?
                warning "#{report.template_name}: #{report.total_changes} changes detected (#{report.drift_severity} severity)"
              elsif report.no_changes?
                success "#{report.template_name}: No drift detected"
              else
                error "#{report.template_name}: Error - #{report.details[:error]}"
              end
            end
            
            # Exit with error if drift detected
            exit 1 if reports.any?(&:drift_detected?)
          end
          
          desc "show", "Show detailed drift report"
          option :template, type: :string, required: true,
                 desc: "Template name"
          def show
            template = options[:template]
            detector = Drift::Detector.new
            
            report = detector.detect_drift(template, get_namespace)
            
            if report.error?
              error "Error detecting drift: #{report.details[:error]}"
              exit 1
            end
            
            info "Drift Report for '#{template}'"
            info "=" * 50
            
            if report.no_changes?
              success "No drift detected"
            else
              warning "Drift detected:"
              
              if report.resources_to_add.any?
                say "\nResources to add:"
                report.resources_to_add.each { |r| say "  + #{r}", :green }
              end
              
              if report.resources_to_change.any?
                say "\nResources to change:"
                report.resources_to_change.each { |r| say "  ~ #{r}", :yellow }
              end
              
              if report.resources_to_destroy.any?
                say "\nResources to destroy:"
                report.resources_to_destroy.each { |r| say "  - #{r}", :red }
              end
              
              say "\nSeverity: #{report.drift_severity}"
              say "Safe to auto-remediate: #{report.safe_to_remediate? ? 'Yes' : 'No'}"
            end
          end
          
          desc "monitor", "Start drift monitoring"
          option :interval, type: :numeric, default: 300,
                 desc: "Check interval in seconds"
          option :once, type: :boolean,
                 desc: "Run once and exit"
          def monitor
            monitor = Drift::Monitor.new(
              interval: options[:interval],
              templates: options[:all] ? :all : [options[:template]].compact
            )
            
            info "Starting drift monitor (interval: #{options[:interval]}s)"
            
            if options[:once]
              monitor.check_all_templates
            else
              info "Press Ctrl+C to stop"
              monitor.start.join
            end
          end
        end
      end
    end
  end
end