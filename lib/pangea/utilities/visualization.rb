# lib/pangea/utilities/visualization.rb
module Pangea
  module Utilities
    module Visualization
      autoload :Graph, 'pangea/utilities/visualization/graph'
      autoload :DependencyGraph, 'pangea/utilities/visualization/dependency_graph'
      autoload :MermaidExporter, 'pangea/utilities/visualization/mermaid_exporter'
      
      def self.generate_graph(template_name, namespace = nil)
        DependencyGraph.new(template_name, namespace).generate
      end
    end
  end
end