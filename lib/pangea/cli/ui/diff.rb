# frozen_string_literal: true

require 'pastel'
require 'diff/lcs'
require 'json'

module Pangea
  module CLI
    module UI
      # Beautiful diff output for terraform changes
      class Diff
        def initialize
          @pastel = Pastel.new
        end
        
        # Display terraform plan diff
        def terraform_plan(plan_output)
          return if plan_output.nil? || plan_output.empty?
          
          sections = parse_plan_output(plan_output)
          
          sections.each do |section|
            display_section(section)
          end
        end
        
        # Display JSON diff (for debugging)
        def json(old_json, new_json)
          old_pretty = JSON.pretty_generate(old_json)
          new_pretty = JSON.pretty_generate(new_json)
          
          diff_lines(old_pretty, new_pretty)
        end
        
        # Display resource diff
        def resource(resource_type, resource_name, changes)
          header = "#{resource_type}.#{resource_name}"
          
          puts "\n#{@pastel.bold(header)}"
          puts @pastel.bright_black("─" * header.length)
          
          changes.each do |attribute, change|
            display_attribute_change(attribute, change)
          end
        end
        
        private
        
        def parse_plan_output(output)
          sections = []
          current_section = nil
          
          output.lines.each do |line|
            case line
            when /^Terraform will perform the following actions:/
              current_section = { type: :header, content: [] }
            when /^  # (.+) will be (.+)$/
              resource = $1
              action = $2
              current_section = { 
                type: :resource, 
                resource: resource,
                action: parse_action(action),
                content: []
              }
              sections << current_section
            when /^      [+-~]/, /^        /
              current_section[:content] << line if current_section
            when /^Plan:/, /^Changes to Outputs:/
              current_section = { type: :summary, content: [line] }
              sections << current_section
            else
              current_section[:content] << line if current_section && line.strip.length > 0
            end
          end
          
          sections
        end
        
        def parse_action(action_text)
          case action_text
          when /created/
            :create
          when /updated in-place/
            :update
          when /replaced/
            :replace
          when /destroyed/
            :destroy
          when /read/
            :read
          else
            :unknown
          end
        end
        
        def display_section(section)
          case section[:type]
          when :resource
            display_resource_section(section)
          when :summary
            display_summary_section(section)
          end
        end
        
        def display_resource_section(section)
          # Resource header with action icon
          icon, color = action_style(section[:action])
          resource_line = "#{icon} #{section[:resource]}"
          
          puts "\n#{@pastel.decorate(resource_line, color)}"
          
          # Process content lines
          section[:content].each do |line|
            display_diff_line(line)
          end
        end
        
        def display_summary_section(section)
          puts "\n" + @pastel.bright_cyan("─" * 60)
          section[:content].each do |line|
            if line =~ /(\d+) to add, (\d+) to change, (\d+) to destroy/
              add, change, destroy = $1.to_i, $2.to_i, $3.to_i
              
              parts = []
              parts << @pastel.green("#{add} to add") if add > 0
              parts << @pastel.yellow("#{change} to change") if change > 0
              parts << @pastel.red("#{destroy} to destroy") if destroy > 0
              
              puts @pastel.bold("Plan: ") + parts.join(", ")
            else
              puts line
            end
          end
        end
        
        def display_diff_line(line)
          case line
          when /^      \+ (.+)$/
            # Added line
            content = $1
            puts @pastel.green("  + #{content}")
          when /^      - (.+)$/
            # Removed line
            content = $1
            puts @pastel.red("  - #{content}")
          when /^      ~ (.+)$/
            # Changed line
            content = $1
            if content =~ /(.+) = (.+) -> (.+)$/
              attr = $1.strip
              old_val = $2.strip
              new_val = $3.strip
              puts "  #{@pastel.yellow('~')} #{attr} = #{format_value_change(old_val, new_val)}"
            else
              puts @pastel.yellow("  ~ #{content}")
            end
          when /^        (.+)$/
            # Context line
            puts @pastel.bright_black("    #{$1}")
          else
            # Keep original formatting
            puts line
          end
        end
        
        def display_attribute_change(attribute, change)
          if change.is_a?(Hash) && change[:old] && change[:new]
            old_val = format_value(change[:old])
            new_val = format_value(change[:new])
            
            puts "  #{@pastel.yellow('~')} #{attribute}: #{format_value_change(old_val, new_val)}"
          elsif change.is_a?(Hash) && change[:add]
            puts "  #{@pastel.green('+')} #{attribute}: #{format_value(change[:add])}"
          elsif change.is_a?(Hash) && change[:remove]
            puts "  #{@pastel.red('-')} #{attribute}: #{format_value(change[:remove])}"
          end
        end
        
        def format_value_change(old_val, new_val)
          if old_val.length > 30 || new_val.length > 30
            # Multi-line diff for long values
            "\n    #{@pastel.red("- #{old_val}")}\n    #{@pastel.green("+ #{new_val}")}"
          else
            # Inline diff for short values
            "#{@pastel.red(old_val)} → #{@pastel.green(new_val)}"
          end
        end
        
        def format_value(value)
          case value
          when String
            value =~ /\n/ ? "\n#{value.lines.map { |l| "    #{l}" }.join}" : value
          when Hash, Array
            JSON.pretty_generate(value)
          else
            value.to_s
          end
        end
        
        def action_style(action)
          case action
          when :create
            ["[+]", :green]
          when :update
            ["[~]", :yellow]
          when :replace
            ["[±]", :magenta]
          when :destroy
            ["[-]", :red]
          when :read
            ["[←]", :blue]
          else
            ["[?]", :white]
          end
        end
        
        def diff_lines(old_text, new_text)
          diffs = ::Diff::LCS.diff(old_text.lines, new_text.lines)
          
          line_num = 1
          diffs.each do |diff|
            diff.each do |change|
              case change.action
              when '-'
                puts @pastel.red("- #{change.element.chomp}")
              when '+'
                puts @pastel.green("+ #{change.element.chomp}")
              end
            end
          end
        end
      end
    end
  end
end