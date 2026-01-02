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
            puts "\n#{@pastel.bright_black("Level #{level}:")}"

            nodes.each do |node|
              type, name = node.split('.')
              color = resource_color(type)
              puts "  #{@pastel.decorate('●', color)} #{node}"
            end
          end

          def display_connections(graph)
            puts "\n#{@pastel.bright_black("Dependencies:")}"

            graph.each do |node, deps|
              if deps.any?
                deps.each do |dep|
                  puts "  #{node} → #{dep}"
                end
              end
            end
          end

          def resource_color(type)
            case type
            when /aws_/
              :yellow
            when /google_/
              :blue
            when /azurerm_/
              :cyan
            when /kubernetes_/
              :magenta
            else
              :white
            end
          end
        end
      end
    end
  end
end
