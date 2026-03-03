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
      # Resource, architecture, and component inspection methods
      module ResourceInspection
          private

          def inspect_resources
            resource_modules = []

            Dir.glob(File.join(Pangea::Resources.lib_path, 'aws', '**', '*.rb')).each do |file|
              next if file.include?('/types.rb')

              module_path = file.sub("#{Pangea::Resources.lib_path}/", '').sub('.rb', '')
              service = module_path.split('/')[1]
              resource = File.basename(module_path)

              resource_modules << {
                service: service,
                resource: resource,
                function_name: "aws_#{service}_#{resource}",
                module_path: module_path,
                file: file
              }
            end

            {
              total_count: resource_modules.size,
              by_service: resource_modules.group_by { |r| r[:service] }
                                          .transform_values do |resources|
                { count: resources.size, resources: resources.map { |r| r[:resource] }.sort }
              end,
              resources: resource_modules
            }
          end

          def inspect_resources_summary
            resources = inspect_resources
            {
              total_count: resources[:total_count],
              services_count: resources[:by_service].keys.size,
              top_services: resources[:by_service]
                            .sort_by { |_, v| -v[:count] }
                            .first(10)
                            .to_h
            }
          end

          def inspect_architectures
            architectures = []

            Dir.glob(File.join(Pangea::Architectures.lib_path, 'patterns', '**', '*.rb')).each do |file|
              pattern_name = File.basename(file, '.rb')
              architectures << { name: pattern_name, function_name: "#{pattern_name}_architecture", file: file }
            end

            { total_count: architectures.size, architectures: architectures }
          end

          def inspect_architectures_summary
            archs = inspect_architectures
            { total_count: archs[:total_count], available: archs[:architectures].map { |a| a[:function_name] } }
          end

          def inspect_components
            components = []

            Dir.glob(File.join(Pangea::Components.lib_path, '**', 'component.rb')).each do |file|
              component_name = File.basename(File.dirname(file))
              components << {
                name: component_name,
                function_name: "#{component_name}_component",
                directory: File.dirname(file),
                has_types: File.exist?(File.join(File.dirname(file), 'types.rb')),
                has_readme: File.exist?(File.join(File.dirname(file), 'README.md'))
              }
            end

            { total_count: components.size, components: components }
          end

          def inspect_components_summary
            comps = inspect_components
            { total_count: comps[:total_count], available: comps[:components].map { |c| c[:function_name] } }
          end
        end
      end
    end
  end
