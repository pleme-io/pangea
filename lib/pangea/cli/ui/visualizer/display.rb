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
                         when :active then Boreal.paint('●', :success)
                         when :pending then Boreal.paint('◐', :update)
                         when :failed then Boreal.paint('✗', :error)
                         else '○'
                         end

            puts "#{prefix}#{status_icon} #{resource[:name]}"

            # Key attributes
            if resource[:attributes]
              important_attrs = resource[:attributes].slice(:id, :arn, :location, :size)
              important_attrs.each do |key, value|
                puts "#{prefix}  #{Boreal.paint("#{key}:", :muted)} #{value}"
              end
            end
          end

          def progress_bar(current, total, width: 20)
            return "" if total == 0

            percentage = (current.to_f / total * 100).round
            filled = (width * percentage / 100).round
            empty = width - filled

            bar = Boreal.paint("█" * filled, :success) + Boreal.paint("░" * empty, :muted)
            "#{bar} #{percentage}%"
          end

          def display_plan_details(details)
            puts "\n" + Boreal.bold("Detailed Changes:")

            # Group by change type
            { create: :create, update: :update, destroy: :delete }.each do |action, role|
              next unless details[action] && details[action].any?

              puts "\n#{Boreal.paint(action.to_s.capitalize, role)}:"
              details[action].each do |resource|
                puts "  • #{resource[:type]}.#{resource[:name]}"
                if resource[:reason]
                  puts "    #{Boreal.paint(resource[:reason], :muted)}"
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
              puts "#{prefix}├─ #{Boreal.paint(node[:name], :primary)}"
              if node[:source]
                puts "#{prefix}│  #{Boreal.paint("source: #{node[:source]}", :muted)}"
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
