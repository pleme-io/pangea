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
      module CommandDisplay
        # State and resource display utilities
        module StateDisplay
          # Display state information
          def display_state_info(state_result, title: 'Current State')
            formatter.subsection_header(title, icon: :state)

            if state_result[:success]
              display_state_resources(state_result[:resources] || [])
            else
              display_state_error(state_result)
            end

            formatter.blank_line
          end

          # Display terraform outputs
          def display_terraform_outputs(output_result)
            return unless output_result[:success] && output_result[:data]

            outputs = output_result[:data]
            return if outputs.empty?

            formatter.subsection_header('Outputs', icon: :output)

            outputs.each do |name, data|
              formatted_value = format_terraform_output(data)
              formatter.kv_pair(name, formatted_value)
            end

            formatter.blank_line
          end

          # Display resource list
          def display_resource_list(resources, title: 'Resources')
            return if resources.nil? || resources.empty?

            formatter.subsection_header(title, icon: :resource)

            resources.each do |resource|
              display_single_resource(resource)
            end

            formatter.blank_line
          end

          private

          def display_state_resources(resources)
            if resources.empty?
              formatter.status(:info, 'No resources found in state')
              formatter.kv_pair('Status', 'Empty state (no resources deployed)')
            else
              formatter.kv_pair('Resources', Boreal.paint(resources.count.to_s, :primary))
              display_grouped_resources(resources)
            end
          end

          def display_grouped_resources(resources)
            grouped = resources.group_by { |r| r.split('.').first }
            grouped.sort.each do |type, type_resources|
              formatter.list_items(
                ["#{Boreal.paint(type, :primary)}: #{type_resources.count} instance(s)"],
                indent: 2
              )
            end
          end

          def display_state_error(state_result)
            formatter.status(:error, 'Failed to read state')
            formatter.kv_pair('Error', state_result[:error]) if state_result[:error]
          end

          def format_terraform_output(data)
            if data['sensitive']
              Boreal.paint('[sensitive]', :muted)
            else
              format_output_value(data['value'])
            end
          end

          def display_single_resource(resource)
            if resource.is_a?(Hash)
              formatter.resource(
                resource[:type],
                resource[:name],
                attributes: resource[:attributes] || {}
              )
            else
              formatter.list_items([resource])
            end
          end
        end
      end
    end
  end
end
