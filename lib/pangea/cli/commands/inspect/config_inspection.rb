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

module Pangea
  module CLI
    module Commands
      class Inspect
        # Config, namespace, and state inspection methods
        module ConfigInspection
          private

          def inspect_namespaces
            namespaces = Pangea.config.namespaces.map do |ns|
              {
                name: ns.name,
                description: ns.description,
                backend_type: ns.state.type,
                backend_config: sanitize_backend_config(ns),
                tags: ns.tags
              }
            end

            { default: Pangea.config.default_namespace, count: namespaces.size, namespaces: namespaces }
          end

          def sanitize_backend_config(namespace)
            config = namespace.to_terraform_backend

            config[:s3][:kms_key_id] = '***' if config[:s3]&.dig(:kms_key_id)

            config
          end

          def inspect_config
            {
              config_paths: Pangea.config.search_paths,
              config_file: find_config_file,
              default_namespace: Pangea.config.default_namespace,
              terraform_binary: Pangea.config.fetch(:terraform, :binary, default: 'tofu'),
              modules_path: Pangea.config.fetch(:modules, :path, default: 'modules'),
              cache_directory: Pangea.config.fetch(:cache, :directory, default: '~/.pangea/cache')
            }
          end

          def find_config_file
            Pangea.config.search_paths.each do |path|
              %w[pangea.yml pangea.yaml].each do |filename|
                file = File.join(path, filename)
                return file if File.exist?(file)
              end
            end
            nil
          end

          def inspect_state(file, template: nil, namespace: nil)
            return { error: 'File required for state inspection' } unless file

            namespace ||= Pangea.config.default_namespace
            ns = Pangea.config.namespace(namespace)
            return { error: "Namespace '#{namespace}' not found" } unless ns

            compiler = Compilation::TemplateCompiler.new
            templates = compiler.extract_templates(file)

            templates = templates.select { |t| t[:name].to_s == template.to_s } if template

            state_info = templates.map { |tmpl| build_state_info(tmpl, namespace, ns, compiler) }

            { namespace: namespace, backend_type: ns.state.type, templates: state_info }
          end

          def build_state_info(tmpl, namespace, ns, compiler)
            workspace_dir = compiler.workspace_directory(namespace, tmpl[:name])
            state_file = case ns.state.type
                         when 'local'
                           File.join(workspace_dir, ns.state.config.path || 'terraform.tfstate')
                         when 's3'
                           "s3://#{ns.state.config.bucket}/#{ns.state.config.key}/#{tmpl[:name]}/terraform.tfstate"
                         end

            {
              template: tmpl[:name],
              namespace: namespace,
              backend_type: ns.state.type,
              state_location: state_file,
              workspace_directory: workspace_dir,
              initialized: Dir.exist?(File.join(workspace_dir, '.terraform'))
            }
          end

          def render_template(file, template: nil, namespace: nil)
            return { error: 'File required for rendering' } unless file
            return { error: "File not found: #{file}" } unless File.exist?(file)

            namespace ||= Pangea.config.default_namespace
            compiler = Compilation::TemplateCompiler.new

            results = compiler.compile_file(file, namespace: namespace, template: template)

            results.map do |result|
              {
                template: result[:name],
                namespace: namespace,
                success: result[:success],
                json: result[:success] ? JSON.parse(result[:json]) : nil,
                error: result[:error],
                terraform_version: result[:terraform_version]
              }
            end
          rescue StandardError => e
            { error: "Compilation failed: #{e.message}" }
          end
        end
      end
    end
  end
end
