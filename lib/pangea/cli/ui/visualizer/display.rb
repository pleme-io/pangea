# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module CLI
    module UI
      class Visualizer
        module Display
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
        end
      end
    end
  end
end
