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
require 'terraform-synthesizer'

module Pangea
  module CLI
    module Services
      # Synthesizes Terraform JSON from a pangea-architectures module.
      #
      # Given a workspace config with an architecture name and config hash,
      # loads the architecture class, calls .build(synth, config), injects
      # provider requirements, and returns the Terraform JSON string.
      class ArchitectureService
        def initialize(ui:)
          @ui = ui
        end

        # Synthesize Terraform JSON for a workspace definition.
        #
        # @param workspace_config [WorkspaceConfig] workspace definition from pangea.yml
        # @return [String] Terraform JSON
        def synthesize(workspace_config)
          arch_class = resolve_architecture(workspace_config.architecture)
          synth = create_synthesizer

          arch_class.build(synth, workspace_config.config.transform_keys(&:to_sym))

          inject_providers(synth, workspace_config.providers)
          inject_backend(synth, workspace_config)

          JSON.pretty_generate(synth.synthesis)
        end

        # List available architecture names.
        #
        # @return [Array<String>]
        def available_architectures
          require 'pangea/architectures'
          Pangea::Architectures.constants
                               .select { |c| Pangea::Architectures.const_get(c).respond_to?(:build) }
                               .map { |c| to_snake_case(c.to_s) }
        end

        private

        def resolve_architecture(name)
          require 'pangea/architectures'

          # Convert snake_case name to PascalCase module constant
          const_name = name.split('_').map(&:capitalize).join
          unless Pangea::Architectures.const_defined?(const_name)
            raise ArgumentError,
                  "Unknown architecture '#{name}'. Available: #{available_architectures.join(', ')}"
          end

          arch = Pangea::Architectures.const_get(const_name)
          unless arch.respond_to?(:build)
            raise ArgumentError, "Architecture '#{name}' does not implement .build(synth, config)"
          end

          arch
        end

        def create_synthesizer
          synth = TerraformSynthesizer.new

          # Extend with all registered resource modules
          Pangea::Resources::ResourceRegistry.registered_resources.each do |mod|
            synth.extend(mod)
          end

          # Extend with all registered architecture modules
          Pangea::ArchitectureRegistry.registered_architectures.each do |mod|
            synth.extend(mod)
          end

          synth
        rescue NameError
          # Fallback if registries not loaded — plain synthesizer works for
          # pangea-architectures which uses synth.resource_type() directly
          TerraformSynthesizer.new
        end

        def inject_providers(synth, providers)
          return if providers.nil? || providers.empty?

          required_providers = {}
          provider_configs = {}

          providers.each do |provider_name, provider_config|
            name = provider_name.to_s
            cfg = provider_config.transform_keys(&:to_sym)

            source = provider_source(name)
            version = cfg.delete(:version) || '~> 5.0'

            required_providers[name] = { source: source, version: version }
            provider_configs[name] = cfg.reject { |_, v| v.nil? }
          end

          # Inject into synthesis via direct hash merge
          synthesis = synth.synthesis
          synthesis['terraform'] ||= {}
          synthesis['terraform']['required_providers'] = required_providers
          synthesis['provider'] = provider_configs unless provider_configs.empty?
        end

        def inject_backend(synth, workspace_config)
          backend = workspace_config.backend
          synthesis = synth.synthesis
          synthesis['terraform'] ||= {}

          backend_hash = backend.to_terraform_backend
          synthesis['terraform']['backend'] = backend_hash
        end

        def provider_source(name)
          case name
          when 'aws' then 'hashicorp/aws'
          when 'azurerm' then 'hashicorp/azurerm'
          when 'google', 'gcp' then 'hashicorp/google'
          when 'cloudflare' then 'cloudflare/cloudflare'
          when 'hcloud' then 'hetznercloud/hcloud'
          when 'datadog' then 'DataDog/datadog'
          else "hashicorp/#{name}"
          end
        end

        def to_snake_case(str)
          str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
             .gsub(/([a-z\d])([A-Z])/, '\1_\2')
             .downcase
        end
      end
    end
  end
end
