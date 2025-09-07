# lib/pangea/utilities/visualization/graph.rb
module Pangea
  module Utilities
    module Visualization
      class Graph
        attr_reader :nodes, :edges
        
        def initialize
          @nodes = {}
          @edges = []
        end
        
        def add_node(id, attributes = {})
          @nodes[id] = Node.new(id, attributes)
        end
        
        def add_edge(from, to, attributes = {})
          @edges << Edge.new(from, to, attributes)
        end
        
        def get_node(id)
          @nodes[id]
        end
        
        def find_edges(from: nil, to: nil)
          @edges.select do |edge|
            (from.nil? || edge.from == from) &&
            (to.nil? || edge.to == to)
          end
        end
        
        def direct_dependencies(node_id)
          find_edges(from: node_id).map(&:to).uniq
        end
        
        def direct_dependents(node_id)
          find_edges(to: node_id).map(&:from).uniq
        end
        
        def all_dependencies(node_id, visited = Set.new)
          return [] if visited.include?(node_id)
          visited.add(node_id)
          
          direct = direct_dependencies(node_id)
          indirect = direct.flat_map { |dep| all_dependencies(dep, visited) }
          
          (direct + indirect).uniq
        end
        
        def to_h
          {
            nodes: @nodes.transform_values(&:to_h),
            edges: @edges.map(&:to_h)
          }
        end
        
        class Node
          attr_reader :id, :attributes
          
          def initialize(id, attributes = {})
            @id = id
            @attributes = attributes
          end
          
          def type
            @attributes[:type]
          end
          
          def name
            @attributes[:name]
          end
          
          def to_h
            { id: @id }.merge(@attributes)
          end
        end
        
        class Edge
          attr_reader :from, :to, :attributes
          
          def initialize(from, to, attributes = {})
            @from = from
            @to = to
            @attributes = attributes
          end
          
          def type
            @attributes[:type]
          end
          
          def to_h
            { from: @from, to: @to }.merge(@attributes)
          end
        end
      end
    end
  end
end