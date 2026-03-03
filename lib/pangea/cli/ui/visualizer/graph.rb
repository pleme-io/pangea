# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class Visualizer
        module Graph
          def build_dependency_graph(resources)
            graph = {}

            resources.each do |resource|
              node = "#{resource[:type]}.#{resource[:name]}"
              graph[node] = []

              if resource[:depends_on]
                resource[:depends_on].each do |dep|
                  graph[node] << dep
                end
              end
            end

            graph
          end

          def topological_levels(graph)
            # Find nodes with no dependencies
            in_degree = Hash.new(0)
            graph.each do |node, deps|
              deps.each { |dep| in_degree[dep] += 1 }
            end

            levels = []
            current_level = graph.keys.select { |n| in_degree[n] == 0 }

            while current_level.any?
              levels << current_level
              next_level = []

              current_level.each do |node|
                graph[node].each do |dep|
                  in_degree[dep] -= 1
                  next_level << dep if in_degree[dep] == 0
                end
              end

              current_level = next_level.uniq
            end

            levels
          end

          def display_graph_level(nodes, level)
            puts "\n#{Boreal.paint("Level #{level}:", :muted)}"

            nodes.each do |node|
              type, _name = node.split('.')
              role = resource_role(type)
              puts "  #{Boreal.paint('●', role)} #{node}"
            end
          end

          def display_connections(graph)
            puts "\n#{Boreal.paint("Dependencies:", :muted)}"

            graph.each do |node, deps|
              if deps.any?
                deps.each do |dep|
                  puts "  #{node} → #{dep}"
                end
              end
            end
          end

          def resource_role(type)
            case type
            when /aws_/       then :update
            when /google_/    then :info
            when /azurerm_/   then :primary
            when /kubernetes_/ then :replace
            else :text
            end
          end
        end
      end
    end
  end
end
