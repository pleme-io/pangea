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
    module Presenters
      # Destroy-specific display logic.
      class DestroyPresenter < BasePresenter
        def resources_to_destroy(resources, _template_name)
          formatter.subsection_header('Resources to Destroy', icon: :warning)
          formatter.blank_line
          formatter.status(:warning, "The following #{resources.count} resource(s) will be permanently deleted:")
          formatter.blank_line

          grouped = resources.group_by { |r| r.split('.').first }

          grouped.sort.each do |type, type_resources|
            formatter.list_items(
              ["#{Boreal.paint(type, :delete)}: #{type_resources.count} instance(s)"],
              icon: "\u2212", color: :delete, indent: 2
            )

            type_resources.first(3).each do |resource|
              formatter.list_items(
                [Boreal.paint(resource, :muted)],
                icon: "\u2022", color: :delete, indent: 4
              )
            end

            next unless type_resources.count > 3

            formatter.list_items(
              [Boreal.paint("... and #{type_resources.count - 3} more", :muted)],
              icon: "\u2022", color: :delete, indent: 4
            )
          end

          formatter.blank_line
          formatter.kv_pair('Total resources', Boreal.paint(resources.count.to_s, :delete))
          formatter.blank_line
        end

        def destroy_confirmation(template_name, resource_count)
          formatter.blank_line
          formatter.warning_box(
            'DESTRUCTION WARNING',
            [
              "This will PERMANENTLY DELETE #{resource_count} resource(s) from template '#{template_name}'",
              'This action CANNOT be undone',
              'All data will be LOST'
            ],
            width: 70
          )
          formatter.blank_line
          formatter.status(:warning, 'Press Ctrl+C within 10 seconds to cancel...')
        end

        def destroy_success(template_name, namespace:, resource_count:)
          operation_success('Destroy', details: {
            'Template' => template_name,
            'Resources destroyed' => resource_count.to_s,
            'Namespace' => namespace
          })
        end

        def workspace_not_found(workspace)
          formatter.status(:error, 'Workspace not found')
          formatter.kv_pair('Path', workspace, indent: 2)
          formatter.blank_line
          formatter.status(:info, "Run 'pangea apply' first to create resources")
        end

        def no_resources_in_state
          formatter.status(:info, 'No resources found in state')
          formatter.kv_pair('Status', 'Nothing to destroy', indent: 2)
          formatter.blank_line
        end

        def workspace_cleaned(workspace)
          formatter.status(:success, 'Workspace cleaned')
          formatter.kv_pair('Path', workspace, indent: 2)
          formatter.blank_line
        end
      end
    end
  end
end
