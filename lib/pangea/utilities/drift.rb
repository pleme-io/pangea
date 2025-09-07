# lib/pangea/utilities/drift.rb
module Pangea
  module Utilities
    module Drift
      autoload :Detector, 'pangea/utilities/drift/detector'
      autoload :Monitor, 'pangea/utilities/drift/monitor'
      autoload :Remediator, 'pangea/utilities/drift/remediator'
      autoload :Report, 'pangea/utilities/drift/report'
      
      def self.detect(template_name, namespace = nil)
        Detector.new.detect_drift(template_name, namespace)
      end
    end
  end
end