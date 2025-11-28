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
    module UI
      # Common command display utilities
      module CommandDisplay
        def formatter
          @formatter ||= OutputFormatter.new
        end

        # Display command header with title
        def display_command_header(command_name, description: nil, icon: nil)
          formatter.section_header(command_name, icon: icon, width: 70)

          if description
            puts formatter.pastel.bright_black(description)
            formatter.blank_line
          end
        end

        # Display namespace information
        def display_namespace_info(namespace_entity)
          formatter.subsection_header('Namespace', icon: :namespace)

          formatter.kv_pair('Name', formatter.pastel.bold(namespace_entity.name))
          formatter.kv_pair('Backend', formatter.pastel.cyan(namespace_entity.state.type.to_s))

          if namespace_entity.s3_backend?
            formatter.kv_pair('Bucket', namespace_entity.state.config.bucket, indent: 4)
            formatter.kv_pair('Region', namespace_entity.state.config.region, indent: 4)
          elsif namespace_entity.local_backend?
            formatter.kv_pair('Path', namespace_entity.state.config.path, indent: 4)
          end

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
            formatter.kv_pair('Template', metadata[:template]) if metadata[:template]
            formatter.kv_pair('Source', metadata[:source_file]) if metadata[:source_file]
            formatter.kv_pair('Last compiled', metadata[:compilation_time]) if metadata[:compilation_time]
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
            puts formatter.pastel.bright_black(details)
          end

          formatter.blank_line
        end

        # Display state information
        def display_state_info(state_result, title: 'Current State')
          formatter.subsection_header(title, icon: :state)

          if state_result[:success]
            resources = state_result[:resources] || []

            if resources.empty?
              formatter.status(:info, 'No resources found in state')
              formatter.kv_pair('Status', 'Empty state (no resources deployed)')
            else
              formatter.kv_pair('Resources', formatter.pastel.cyan(resources.count.to_s))

              # Group by type
              grouped = resources.group_by { |r| r.split('.').first }
              grouped.sort.each do |type, type_resources|
                formatter.list_items(
                  ["#{formatter.pastel.cyan(type)}: #{type_resources.count} instance(s)"],
                  indent: 2
                )
              end
            end
          else
            formatter.status(:error, 'Failed to read state')
            formatter.kv_pair('Error', state_result[:error]) if state_result[:error]
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
            value = data['value']
            sensitive = data['sensitive']

            formatted_value = if sensitive
              formatter.pastel.bright_black('[sensitive]')
            else
              format_output_value(value)
            end

            formatter.kv_pair(name, formatted_value)
          end

          formatter.blank_line
        end

        # Display resource list
        def display_resource_list(resources, title: 'Resources')
          return if resources.nil? || resources.empty?

          formatter.subsection_header(title, icon: :resource)

          resources.each do |resource|
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

        # Display cost estimation
        def display_cost_estimation(resources)
          estimated_cost = estimate_monthly_cost(resources)
          return if estimated_cost.zero?

          formatter.subsection_header('Cost Estimation', icon: :info)

          formatter.kv_pair(
            'Estimated monthly cost',
            formatter.pastel.cyan("$#{estimated_cost}/month")
          )

          formatter.blank_line
          puts formatter.pastel.bright_black(
            'Note: This is a rough estimate. Actual costs may vary based on usage.'
          )
          formatter.blank_line
        end

        # Display execution time
        def display_execution_time(start_time, operation: 'Operation')
          elapsed = Time.now - start_time
          formatted_time = format_duration(elapsed)

          formatter.kv_pair(
            "#{operation} duration",
            formatter.pastel.bright_black(formatted_time)
          )
        end

        private

        def format_output_value(value)
          case value
          when String
            formatter.pastel.bright_black(value)
          when Array
            formatter.pastel.bright_black("[#{value.join(', ')}]")
          when Hash
            formatter.pastel.bright_black(value.to_json)
          when Numeric
            formatter.pastel.cyan(value.to_s)
          when TrueClass, FalseClass
            formatter.pastel.yellow(value.to_s)
          else
            formatter.pastel.bright_black(value.to_s)
          end
        end

        def estimate_monthly_cost(resources)
          total = 0.0

          resources.each do |resource|
            resource_type = resource.is_a?(Hash) ? resource[:type] : resource.to_s.split('.').first

            cost = case resource_type
                   when 'aws_route53_zone'
                     0.50
                   when 'aws_route53_record'
                     0.001
                   when 'aws_s3_bucket'
                     5.00
                   when 'aws_lambda_function'
                     10.00
                   when 'aws_rds_cluster', 'aws_db_instance'
                     100.00
                   when 'aws_ec2_instance', 'aws_instance'
                     50.00
                   when 'aws_ecs_service'
                     30.00
                   when 'aws_eks_cluster'
                     200.00
                   else
                     1.00
                   end

            total += cost
          end

          total.round(2)
        end

        def format_duration(seconds)
          if seconds < 1
            "#{(seconds * 1000).round}ms"
          elsif seconds < 60
            "#{seconds.round(2)}s"
          else
            minutes = (seconds / 60).floor
            secs = (seconds % 60).round
            "#{minutes}m #{secs}s"
          end
        end
      end
    end
  end
end
