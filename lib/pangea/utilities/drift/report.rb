# lib/pangea/utilities/drift/report.rb
require 'time'

module Pangea
  module Utilities
    module Drift
      class Report
        attr_reader :template_name, :status, :details, :timestamp
        
        def initialize(template_name, status, details = {})
          @template_name = template_name
          @status = status
          @details = details
          @timestamp = Time.now
        end
        
        def drift_detected?
          @status == :drift_detected
        end
        
        def no_changes?
          @status == :no_changes
        end
        
        def error?
          @status == :error
        end
        
        def resources_to_add
          @details[:resources_to_add] || []
        end
        
        def resources_to_change
          @details[:resources_to_change] || []
        end
        
        def resources_to_destroy
          @details[:resources_to_destroy] || []
        end
        
        def total_changes
          resources_to_add.length + resources_to_change.length + resources_to_destroy.length
        end
        
        def drift_severity
          @details[:drift_severity] || calculate_severity
        end
        
        def safe_to_remediate?
          drift_severity == :low && resources_to_destroy.empty?
        end
        
        def to_h
          {
            template_name: @template_name,
            status: @status,
            timestamp: @timestamp.iso8601,
            total_changes: total_changes,
            drift_severity: drift_severity,
            details: @details
          }
        end
        
        def to_s
          if drift_detected?
            "Drift detected in #{@template_name}: #{total_changes} changes (#{drift_severity} severity)"
          elsif no_changes?
            "No drift detected in #{@template_name}"
          else
            "Error detecting drift in #{@template_name}: #{@details[:error]}"
          end
        end
        
        private
        
        def calculate_severity
          return :none if total_changes == 0
          return :critical if resources_to_destroy.length > 0
          return :high if resources_to_change.length > 5
          return :medium if resources_to_change.length > 2
          :low
        end
      end
    end
  end
end