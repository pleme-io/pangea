# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'boreal'
require 'tty-box'
require 'tty-table'
require_relative 'visualizer/graph'
require_relative 'visualizer/display'
require_relative 'visualizer/cost'
require_relative 'visualizer/statistics'

module Pangea
  module CLI
    module UI
      # Resource dependency and state visualization
      class Visualizer
        include Graph
        include Display
        include Cost
        include Statistics

        def initialize
          @screen_width = TTY::Screen.width
        end

        # Visualize resource dependencies as a graph
        def dependency_graph(resources)
          puts Boreal.bold("\nResource Dependency Graph")
          puts Boreal.paint("─" * 40, :muted)

          # Build adjacency list
          graph = build_dependency_graph(resources)

          # Topological sort to find levels
          levels = topological_levels(graph)

          # Display each level
          levels.each_with_index do |level, idx|
            display_graph_level(level, idx)
          end

          # Show connections
          display_connections(graph)
        end

        # Visualize terraform state as a tree
        def state_tree(state_data)
          puts Boreal.bold("\nState Tree")
          puts Boreal.paint("─" * 40, :muted)

          # Group resources by type
          grouped = state_data.group_by { |r| r[:type] }

          grouped.each do |type, resources|
            # Type header
            puts "\n#{Boreal.paint('▼', :primary)} #{Boreal.bold(type)} (#{resources.count})"

            resources.each do |resource|
              display_resource_node(resource, indent: 2)
            end
          end
        end

        # Plan visualization with impact analysis
        def plan_impact(plan_data)
          create_count = plan_data[:create].count
          update_count = plan_data[:update].count
          delete_count = plan_data[:destroy].count
          total = create_count + update_count + delete_count

          return if total == 0

          # Impact summary box
          box = TTY::Box.frame(
            width: 60,
            height: 10,
            padding: 1,
            title: { top_center: " Plan Impact Analysis " }
          ) do
            lines = []

            lines << "Total Changes: #{Boreal.bold(total.to_s)}"
            lines << ""

            if create_count > 0
              lines << "#{Boreal.paint('▲', :create)} Create: #{create_count} resource(s)"
              lines << "   Risk: #{Boreal.paint('Low', :create)} - New resources"
            end

            if update_count > 0
              lines << "#{Boreal.paint('◆', :update)} Update: #{update_count} resource(s)"
              lines << "   Risk: #{Boreal.paint('Medium', :update)} - Existing resources modified"
            end

            if delete_count > 0
              lines << "#{Boreal.paint('▼', :delete)} Delete: #{delete_count} resource(s)"
              lines << "   Risk: #{Boreal.paint('High', :delete)} - Data loss possible"
            end

            lines.join("\n")
          end

          puts box

          # Detailed breakdown
          if plan_data[:details]
            display_plan_details(plan_data[:details])
          end
        end

        # Module hierarchy visualization
        def module_hierarchy(modules)
          puts Boreal.bold("\nModule Hierarchy")
          puts Boreal.paint("─" * 40, :muted)

          # Build tree structure
          tree = build_module_tree(modules)

          # Display tree
          display_module_node(tree, indent: 0)
        end

        # Cost estimation visualization
        def cost_estimate(resources)
          puts Boreal.bold("\nEstimated Monthly Costs")
          puts Boreal.paint("─" * 40, :muted)

          total_cost = 0
          items = []

          resources.each do |resource|
            if cost = estimate_resource_cost(resource)
              total_cost += cost
              items << {
                resource: "#{resource[:type]}.#{resource[:name]}",
                cost: cost,
                details: resource[:size] || resource[:instance_type] || '-'
              }
            end
          end

          # Sort by cost
          items.sort_by! { |i| -i[:cost] }

          # Display table
          table = TTY::Table.new(
            header: ['Resource', 'Details', 'Est. Cost/mo'],
            rows: items.map { |i|
              [
                i[:resource],
                i[:details],
                "$#{i[:cost].round(2)}"
              ]
            }
          )

          puts table.render(:unicode, padding: [0, 1])

          # Total
          puts "\n" + Boreal.bold("Total Estimated Cost: $#{total_cost.round(2)}/month")
          puts Boreal.paint("* Estimates based on typical usage patterns", :muted)
        end
      end
    end
  end
end
