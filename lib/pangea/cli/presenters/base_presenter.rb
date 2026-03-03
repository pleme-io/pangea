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

module Pangea
  module CLI
    module Presenters
      # Shared display logic for all commands.
      # Replaces the CommandDisplay mixin + ValueFormatters + StateDisplay.
      class BasePresenter
        attr_reader :formatter, :ui

        def initialize(formatter: nil, ui: nil)
          @formatter = formatter || UI::OutputFormatter.new
          @ui = ui
        end

        def command_header(title, icon: nil, description: nil)
          formatter.section_header(title, icon: icon, width: 70)
          if description
            puts Boreal.paint(description, :muted)
            formatter.blank_line
          end
        end

        def namespace_info(entity)
          formatter.subsection_header('Namespace', icon: :namespace)
          formatter.kv_pair('Name', Boreal.bold(entity.name))
          formatter.kv_pair('Backend', Boreal.paint(entity.state.type.to_s, :primary))
          backend_details(entity)
          formatter.kv_pair('Description', entity.description) if entity.description
          formatter.blank_line
        end

        def workspace_info(workspace, metadata: nil)
          formatter.subsection_header('Workspace', icon: :workspace)
          formatter.kv_pair('Path', workspace)
          display_workspace_metadata(metadata) if metadata
          formatter.blank_line
        end

        def operation_success(operation, details: {})
          formatter.success_banner("#{operation} Completed Successfully!")
          formatter.summary(details) if details.any?
        end

        def operation_failure(operation, error, details: nil)
          formatter.section_header("#{operation} Failed", icon: :error)
          formatter.status(:error, error)
          if details
            formatter.blank_line
            formatter.subsection_header('Details')
            puts Boreal.paint(details, :muted)
          end
          formatter.blank_line
        end

        def changes_summary(added: 0, changed: 0, destroyed: 0)
          return if added == 0 && changed == 0 && destroyed == 0

          formatter.changes_summary(added: added, changed: changed, destroyed: destroyed)
        end

        def execution_time(start_time, operation: nil)
          elapsed = Time.now - start_time
          label = operation ? "#{operation} completed in" : "Completed in"
          @ui&.say "#{label} #{format_duration(elapsed)}", color: :muted
        end

        def progress(message, status: :pending)
          formatter.progress_message(message, status: status)
        end

        # Terraform output display
        def terraform_outputs(output_result)
          return unless output_result[:success] && output_result[:data]&.any?

          formatter.subsection_header('Outputs', icon: :output)
          output_result[:data].each do |name, data|
            value = data['value']
            if data['sensitive']
              formatter.kv_pair(name, Boreal.paint('<sensitive>', :muted))
            else
              formatter.kv_pair(name, format_output_value(value))
            end
          end
          formatter.blank_line
        end

        private

        def backend_details(entity)
          if entity.s3_backend?
            formatter.kv_pair('Bucket', entity.state.config.bucket, indent: 4)
            formatter.kv_pair('Region', entity.state.config.region, indent: 4)
          elsif entity.local_backend?
            formatter.kv_pair('Path', entity.state.config.path, indent: 4)
          end
        end

        def display_workspace_metadata(metadata)
          formatter.kv_pair('Template', metadata[:template]) if metadata[:template]
          formatter.kv_pair('Source', metadata[:source_file]) if metadata[:source_file]
          formatter.kv_pair('Last compiled', metadata[:compilation_time]) if metadata[:compilation_time]
        end

        def format_duration(seconds)
          if seconds < 60
            "#{seconds.round(2)}s"
          else
            minutes = (seconds / 60).floor
            secs = (seconds % 60).round
            "#{minutes}m #{secs}s"
          end
        end

        def format_output_value(value)
          case value
          when String then value
          when Array  then "[#{value.join(', ')}]"
          when Hash   then value.to_json
          else value.to_s
          end
        end
      end
    end
  end
end
