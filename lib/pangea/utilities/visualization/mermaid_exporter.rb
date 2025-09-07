# lib/pangea/utilities/visualization/mermaid_exporter.rb
module Pangea
  module Utilities
    module Visualization
      class MermaidExporter
        def initialize(graph)
          @graph = graph
        end
        
        def export
          lines = ["graph TD"]
          
          # Add nodes
          @graph.nodes.each do |id, node|
            label = format_node_label(node)
            shape = determine_node_shape(node)
            lines << "    #{sanitize_id(id)}#{shape[0]}\"#{label}\"#{shape[1]}"
          end
          
          lines << ""
          
          # Add edges
          @graph.edges.each do |edge|
            arrow = determine_arrow_style(edge)
            label = edge.attributes[:label] || edge.type
            
            if label
              lines << "    #{sanitize_id(edge.from)} #{arrow}|#{label}| #{sanitize_id(edge.to)}"
            else
              lines << "    #{sanitize_id(edge.from)} #{arrow} #{sanitize_id(edge.to)}"
            end
          end
          
          lines.join("\n")
        end
        
        def export_with_style
          mermaid = export
          
          # Add styling
          styles = generate_styles
          
          if styles.any?
            mermaid += "\n\n"
            styles.each_with_index do |style, index|
              mermaid += "    classDef class#{index} #{style[:definition]}\n"
            end
            
            mermaid += "\n"
            styles.each_with_index do |style, index|
              style[:nodes].each do |node_id|
                mermaid += "    class #{sanitize_id(node_id)} class#{index}\n"
              end
            end
          end
          
          mermaid
        end
        
        private
        
        def sanitize_id(id)
          id.to_s.gsub(/[^a-zA-Z0-9_]/, '_')
        end
        
        def format_node_label(node)
          type = node.type || 'unknown'
          name = node.name || node.id
          
          "#{type}<br/>#{name}"
        end
        
        def determine_node_shape(node)
          case node.type
          when /aws_instance/, /aws_db_instance/
            ['[', ']']  # Rectangle
          when /aws_vpc/, /aws_subnet/
            ['((', '))']  # Circle
          when /aws_lb/, /aws_alb/
            ['([', '])']  # Stadium
          when /aws_s3_bucket/
            ['[(', ')]']  # Cylinder
          else
            ['[', ']']  # Default rectangle
          end
        end
        
        def determine_arrow_style(edge)
          case edge.type
          when 'depends_on', 'references'
            '-->'
          when 'managed_by'
            '-..->'
          when 'data_flow'
            '==>'
          else
            '-->'
          end
        end
        
        def generate_styles
          styles = []
          
          # Group nodes by type for styling
          compute_nodes = @graph.nodes.select { |_, n| n.type =~ /instance/ }.keys
          network_nodes = @graph.nodes.select { |_, n| n.type =~ /vpc|subnet/ }.keys
          storage_nodes = @graph.nodes.select { |_, n| n.type =~ /s3|ebs/ }.keys
          
          if compute_nodes.any?
            styles << {
              definition: "fill:#f9f,stroke:#333,stroke-width:2px",
              nodes: compute_nodes
            }
          end
          
          if network_nodes.any?
            styles << {
              definition: "fill:#9f9,stroke:#333,stroke-width:2px",
              nodes: network_nodes
            }
          end
          
          if storage_nodes.any?
            styles << {
              definition: "fill:#99f,stroke:#333,stroke-width:2px",
              nodes: storage_nodes
            }
          end
          
          styles
        end
      end
    end
  end
end