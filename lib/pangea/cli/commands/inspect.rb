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

require 'json'
require 'pangea'
require 'pangea/cli/commands/base_command'
require 'pangea/compilation/template_compiler'
require 'pangea/resources'
require 'pangea/architectures'

require_relative 'inspect/template_analysis'
require_relative 'inspect/resource_inspection'
require_relative 'inspect/config_inspection'

module Pangea
  module CLI
    module Commands
      # Inspect command for agent-friendly JSON output
      class Inspect < BaseCommand
        include TemplateAnalysis
        include ResourceInspection
        include ConfigInspection

        def run(target = nil, type: 'all', template: nil, format: 'json', namespace: nil)
          ui.debug "Inspecting #{type} for target: #{target || 'system'}"

          result = dispatch_inspection(target, type, template, namespace)
          output_result(result, format: format)
        rescue StandardError => e
          output_result({ error: e.message, backtrace: e.backtrace }, format: format)
        end

        private

        def dispatch_inspection(target, type, template, namespace)
          case type
          when 'all' then inspect_all(target, template: template, namespace: namespace)
          when 'templates' then inspect_templates(target, template: template)
          when 'resources' then inspect_resources
          when 'architectures' then inspect_architectures
          when 'components' then inspect_components
          when 'namespaces' then inspect_namespaces
          when 'config' then inspect_config
          when 'state' then inspect_state(target, template: template, namespace: namespace)
          when 'render' then render_template(target, template: template, namespace: namespace)
          else { error: "Unknown inspection type: #{type}" }
          end
        end

        def inspect_all(file, template: nil, namespace: nil)
          {
            metadata: {
              pangea_version: Pangea::VERSION,
              timestamp: Time.now.iso8601,
              file: file,
              template: template,
              namespace: namespace || Pangea.config.default_namespace
            },
            config: inspect_config,
            namespaces: inspect_namespaces,
            templates: file ? inspect_templates(file, template: template) : {},
            resources: inspect_resources_summary,
            architectures: inspect_architectures_summary,
            components: inspect_components_summary
          }
        end

        def output_result(result, format: 'json')
          case format
          when 'json'
            puts JSON.pretty_generate(result)
          when 'yaml'
            require 'yaml'
            puts result.to_yaml
          else
            ui.error "Unknown format: #{format}"
          end
        end
      end
    end
  end
end
