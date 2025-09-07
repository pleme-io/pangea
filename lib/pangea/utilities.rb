# lib/pangea/utilities.rb
require 'json'
require 'digest'
require 'fileutils'

module Pangea
  module Utilities
    class UtilityError < StandardError; end
    
    # Autoload utilities
    autoload :RemoteState, 'pangea/utilities/remote_state'
    autoload :Drift, 'pangea/utilities/drift'
    autoload :Cost, 'pangea/utilities/cost'
    autoload :Visualization, 'pangea/utilities/visualization'
    autoload :Analysis, 'pangea/utilities/analysis'
    autoload :Validation, 'pangea/utilities/validation'
    autoload :Backup, 'pangea/utilities/backup'
    autoload :Migration, 'pangea/utilities/migration'
    autoload :Monitoring, 'pangea/utilities/monitoring'
    
    def self.version
      "1.0.0"
    end
  end
end