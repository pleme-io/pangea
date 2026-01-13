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
    module Commands
      # Template parsing and compilation operations
      module TemplateOperations
          private

          def parse_templates_with_progress(file_path, template_filter)
            spinner = UI::Spinner.file_operation("Parsing #{File.basename(file_path)}")

            templates = spinner.spin do
              # Simulate template parsing
              sleep 0.5

              all_templates = [
                { name: 'networking', resources: 12 },
                { name: 'compute', resources: 8 },
                { name: 'database', resources: 5 },
                { name: 'monitoring', resources: 15 }
              ]

              if template_filter
                all_templates.select { |t| t[:name] == template_filter }
              else
                all_templates
              end
            end

            handle_empty_templates(templates, template_filter, file_path)
          end

          def handle_empty_templates(templates, template_filter, file_path)
            if templates.empty?
              display_template_error(template_filter, file_path)
              return []
            end

            ui.success "Found #{templates.length} template(s)"
            templates
          end

          def display_template_error(template_filter, file_path)
            if template_filter
              banner.error("Template not found", "Template '#{template_filter}' not found in #{file_path}", [
                             "Available templates: networking, compute, database, monitoring",
                             "Remove --template flag to process all templates"
                           ])
            else
              banner.error("No templates found", "No valid templates found in #{file_path}", [
                             "Check your template syntax",
                             "Ensure templates use the template :name do...end syntax"
                           ])
            end
          end

          def compile_templates_with_progress(templates)
            ui.section "Template Compilation"

            compiled = []

            UI::Spinner.multi_stage(templates.map { |t| "Compiling #{t[:name]}" }) do |_spinner, stage|
              template_name = stage.split(' ').last
              template = templates.find { |t| t[:name] == template_name }

              compilation_time = template[:resources] * 0.1
              sleep compilation_time

              compiled << build_compiled_template(template, compilation_time)
              ui.template_status(template[:name], :compiled, compilation_time)
            end

            puts "\n"
            puts UI::Table.template_summary(compiled)

            compiled
          end

          def build_compiled_template(template, compilation_time)
            {
              name: template[:name],
              resources: template[:resources],
              status: :compiled,
              duration: compilation_time,
              resource_count: template[:resources]
            }
          end
        end
      end
    end
  end
