# lib/pangea/utilities/remote_state.rb
module Pangea
  module Utilities
    module RemoteState
      autoload :Reference, 'pangea/utilities/remote_state/reference'
      autoload :DependencyManager, 'pangea/utilities/remote_state/dependency_manager'
      autoload :OutputRegistry, 'pangea/utilities/remote_state/output_registry'
      
      def self.reference(namespace, template, output)
        Reference.new(namespace, template, output)
      end
    end
  end
end