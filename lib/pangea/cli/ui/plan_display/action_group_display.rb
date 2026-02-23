# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Pangea
  module CLI
    module UI
      module PlanDisplay
        # Handles display of resource action groups (create, update, delete, replace)
        module ActionGroupDisplay
          ACTION_CONFIG = {
            create: { icon: :create, role: :create, label: 'CREATE' },
            update: { icon: :update, role: :update, label: 'UPDATE' },
            delete: { icon: :delete, role: :delete, label: 'DELETE' },
            replace: { icon: :replace, role: :replace, label: 'REPLACE' }
          }.freeze

          # Display a group of resources for a specific action
          def display_action_group(action, resources, resource_analysis)
            config = ACTION_CONFIG[action]
            icon = OutputFormatter::ICONS[config[:icon]]

            formatted_label = Boreal.paint(
              "#{icon} #{config[:label]} (#{resources.count})",
              config[:role]
            )

            puts
            puts "  #{formatted_label}:"

            resources.each do |resource_ref|
              resource_info = find_resource_info(resource_ref, resource_analysis)

              if resource_info
                display_resource_with_details(resource_ref, resource_info, action)
              else
                formatter.list_items([resource_ref], indent: 4)
              end
            end
          end

          # Display resource with its details
          def display_resource_with_details(resource_ref, resource_info, action)
            formatter.list_items([Boreal.bold(resource_ref)], indent: 4)
            display_action_message(action, resource_info)
            display_key_attributes(resource_info)
          end

          private

          def display_action_message(action, resource_info)
            case action
            when :create
              formatter.kv_pair('Action', "Creating new #{resource_info[:type]}", indent: 6)
            when :delete
              formatter.kv_pair('Action', Boreal.paint('Warning: Will destroy existing resource', :error), indent: 6)
            when :update
              formatter.kv_pair('Action', "Modifying existing #{resource_info[:type]}", indent: 6)
            when :replace
              formatter.kv_pair('Action', Boreal.paint('Warning: Will replace (destroy + create)', :replace), indent: 6)
            end
          end

          def display_key_attributes(resource_info)
            return unless resource_info[:attributes]&.any?

            resource_info[:attributes].first(3).each do |key, value|
              formatted_value = format_attribute_value(value)
              formatter.kv_pair(key.to_s, formatted_value, indent: 6)
            end
          end

          def format_attribute_value(value)
            case value
            when String
              value.length > 50 ? "#{value[0..47]}..." : value
            when Array
              value.join(', ')
            when Hash
              value.to_json
            else
              value.to_s
            end
          end
        end
      end
    end
  end
end
