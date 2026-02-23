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

require 'pangea/cli/ui/output_formatter'
require_relative 'command_display/value_formatters'
require_relative 'command_display/state_display'
require_relative 'command_display/cost_estimation'

module Pangea
  module CLI
    module UI
      # Common command display utilities
      module CommandDisplay
        include ValueFormatters
        include StateDisplay
        include CostEstimation

        def formatter
          @formatter ||= OutputFormatter.new
        end

        # Display command header with title
        def display_command_header(command_name, description: nil, icon: nil)
          formatter.section_header(command_name, icon: icon, width: 70)

          if description
            puts Boreal.paint(description, :muted)
            formatter.blank_line
          end
        end

        # Display namespace information
        def display_namespace_info(namespace_entity)
          formatter.subsection_header('Namespace', icon: :namespace)

          formatter.kv_pair('Name', Boreal.bold(namespace_entity.name))
          formatter.kv_pair('Backend', Boreal.paint(namespace_entity.state.type.to_s, :primary))

          display_backend_details(namespace_entity)

          if namespace_entity.description
            formatter.kv_pair('Description', namespace_entity.description)
          end

          formatter.blank_line
        end

        # Display workspace information
        def display_workspace_info(workspace, metadata: nil)
          formatter.subsection_header('Workspace', icon: :workspace)

          formatter.kv_pair('Path', workspace)

          if metadata
            display_workspace_metadata(metadata)
          end

          formatter.blank_line
        end

        # Display compilation warnings
        def display_compilation_warnings(warnings)
          return if warnings.nil? || warnings.empty?

          formatter.warning_box('Compilation Warnings', warnings, width: 70)
        end

        # Display compilation errors
        def display_compilation_errors(errors)
          return if errors.nil? || errors.empty?

          formatter.error_box('Compilation Errors', errors, width: 70)
        end

        # Display operation success
        def display_operation_success(operation, details: {})
          formatter.success_banner("#{operation} Completed Successfully!")

          if details.any?
            formatter.summary(details)
          end
        end

        # Display operation failure
        def display_operation_failure(operation, error, details: nil)
          formatter.section_header("#{operation} Failed", icon: :error)

          formatter.status(:error, error)

          if details
            formatter.blank_line
            formatter.subsection_header('Details')
            puts Boreal.paint(details, :muted)
          end

          formatter.blank_line
        end

        # Display changes summary
        def display_changes_summary(added: 0, changed: 0, destroyed: 0)
          return if added == 0 && changed == 0 && destroyed == 0

          formatter.changes_summary(
            added: added,
            changed: changed,
            destroyed: destroyed
          )
        end

        # Display progress indicator
        def display_progress(message, status: :pending)
          formatter.progress_message(message, status: status)
        end

        private

        def display_backend_details(namespace_entity)
          if namespace_entity.s3_backend?
            formatter.kv_pair('Bucket', namespace_entity.state.config.bucket, indent: 4)
            formatter.kv_pair('Region', namespace_entity.state.config.region, indent: 4)
          elsif namespace_entity.local_backend?
            formatter.kv_pair('Path', namespace_entity.state.config.path, indent: 4)
          end
        end

        def display_workspace_metadata(metadata)
          formatter.kv_pair('Template', metadata[:template]) if metadata[:template]
          formatter.kv_pair('Source', metadata[:source_file]) if metadata[:source_file]
          formatter.kv_pair('Last compiled', metadata[:compilation_time]) if metadata[:compilation_time]
        end
      end
    end
  end
end
