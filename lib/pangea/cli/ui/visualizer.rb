# frozen_string_literal: true

require 'tty-box'
require 'tty-table'
require 'pastel'

module Pangea
  module CLI
    module UI
      # Resource dependency and state visualization
      class Visualizer
        def initialize
          @pastel = Pastel.new
          @screen_width = TTY::Screen.width
        end
        
        # Visualize resource dependencies as a graph
        def dependency_graph(resources)
          puts @pastel.bold("\nResource Dependency Graph")
          puts @pastel.bright_black("─" * 40)
          
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
          puts @pastel.bold("\nState Tree")
          puts @pastel.bright_black("─" * 40)
          
          # Group resources by type
          grouped = state_data.group_by { |r| r[:type] }
          
          grouped.each do |type, resources|
            # Type header
            puts "\n#{@pastel.cyan('▼')} #{@pastel.bold(type)} (#{resources.count})"
            
            resources.each do |resource|
              display_resource_node(resource, indent: 2)
            end
          end
        end
        
        # Resource statistics dashboard
        def statistics_dashboard(stats)
          # Title
          title = " Infrastructure Statistics "
          box = TTY::Box.frame(
            width: @screen_width - 4,
            height: 20,
            padding: 1,
            title: { top_center: title },
            style: {
              fg: :bright_cyan,
              border: {
                fg: :bright_blue
              }
            }
          ) do
            lines = []
            
            # Summary stats
            lines << @pastel.bold("Summary")
            lines << "  Total Resources: #{stats[:total_resources]}"
            lines << "  Namespaces: #{stats[:namespaces]}"
            lines << "  Last Updated: #{stats[:last_updated]}"
            lines << ""
            
            # Resource breakdown
            lines << @pastel.bold("Resources by Type")
            stats[:by_type].each do |type, count|
              bar = progress_bar(count, stats[:total_resources], width: 20)
              lines << "  #{type.ljust(20)} #{bar} #{count}"
            end
            lines << ""
            
            # Provider breakdown
            lines << @pastel.bold("Resources by Provider")
            stats[:by_provider].each do |provider, count|
              percentage = (count.to_f / stats[:total_resources] * 100).round(1)
              lines << "  #{provider.ljust(20)} #{percentage}% (#{count})"
            end
            
            lines.join("\n")
          end
          
          puts box
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
            
            lines << "Total Changes: #{@pastel.bold(total.to_s)}"
            lines << ""
            
            if create_count > 0
              lines << "#{@pastel.green('▲')} Create: #{create_count} resource(s)"
              lines << "   Risk: #{@pastel.green('Low')} - New resources"
            end
            
            if update_count > 0
              lines << "#{@pastel.yellow('◆')} Update: #{update_count} resource(s)"
              lines << "   Risk: #{@pastel.yellow('Medium')} - Existing resources modified"
            end
            
            if delete_count > 0
              lines << "#{@pastel.red('▼')} Delete: #{delete_count} resource(s)"
              lines << "   Risk: #{@pastel.red('High')} - Data loss possible"
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
          puts @pastel.bold("\nModule Hierarchy")
          puts @pastel.bright_black("─" * 40)
          
          # Build tree structure
          tree = build_module_tree(modules)
          
          # Display tree
          display_module_node(tree, indent: 0)
        end
        
        # Cost estimation visualization
        def cost_estimate(resources)
          puts @pastel.bold("\nEstimated Monthly Costs")
          puts @pastel.bright_black("─" * 40)
          
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
          puts "\n" + @pastel.bold("Total Estimated Cost: $#{total_cost.round(2)}/month")
          puts @pastel.bright_black("* Estimates based on typical usage patterns")
        end
        
        private
        
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
        
        def display_resource_node(resource, indent:)
          prefix = " " * indent
          status_icon = case resource[:status]
                       when :active then @pastel.green('●')
                       when :pending then @pastel.yellow('◐')
                       when :failed then @pastel.red('✗')
                       else '○'
                       end
          
          puts "#{prefix}#{status_icon} #{resource[:name]}"
          
          # Key attributes
          if resource[:attributes]
            important_attrs = resource[:attributes].slice(:id, :arn, :location, :size)
            important_attrs.each do |key, value|
              puts "#{prefix}  #{@pastel.bright_black("#{key}:")} #{value}"
            end
          end
        end
        
        def progress_bar(current, total, width: 20)
          return "" if total == 0
          
          percentage = (current.to_f / total * 100).round
          filled = (width * percentage / 100).round
          empty = width - filled
          
          bar = @pastel.green("█" * filled) + @pastel.bright_black("░" * empty)
          "#{bar} #{percentage}%"
        end
        
        def display_plan_details(details)
          puts "\n" + @pastel.bold("Detailed Changes:")
          
          # Group by change type
          [:create, :update, :destroy].each do |action|
            next unless details[action] && details[action].any?
            
            color = case action
                   when :create then :green
                   when :update then :yellow
                   when :destroy then :red
                   end
            
            puts "\n#{@pastel.decorate(action.to_s.capitalize, color)}:"
            details[action].each do |resource|
              puts "  • #{resource[:type]}.#{resource[:name]}"
              if resource[:reason]
                puts "    #{@pastel.bright_black(resource[:reason])}"
              end
            end
          end
        end
        
        def build_module_tree(modules, parent = nil)
          tree = { name: parent || 'root', children: [] }
          
          modules.select { |m| m[:parent] == parent }.each do |mod|
            child = {
              name: mod[:name],
              source: mod[:source],
              children: build_module_tree(modules, mod[:name])[:children]
            }
            tree[:children] << child
          end
          
          tree
        end
        
        def display_module_node(node, indent:)
          prefix = " " * indent
          
          if node[:name] != 'root'
            puts "#{prefix}├─ #{@pastel.cyan(node[:name])}"
            if node[:source]
              puts "#{prefix}│  #{@pastel.bright_black("source: #{node[:source]}")}"
            end
          end
          
          node[:children].each_with_index do |child, idx|
            is_last = idx == node[:children].length - 1
            display_module_node(child, indent: indent + 2)
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
        
        def estimate_resource_cost(resource)
          # Simplified cost estimation based on resource type
          case resource[:type]
          when 'aws_instance'
            instance_costs = {
              't2.micro' => 8.50,
              't2.small' => 17.00,
              't2.medium' => 34.00,
              't3.micro' => 7.50,
              't3.small' => 15.00,
              't3.medium' => 30.00
            }
            instance_costs[resource[:instance_type]] || 50.00
          when 'aws_rds_cluster'
            100.00
          when 'aws_s3_bucket'
            5.00
          when 'aws_lambda_function'
            10.00
          else
            nil
          end
        end
      end
    end
  end
end