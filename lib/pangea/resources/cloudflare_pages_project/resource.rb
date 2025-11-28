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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_pages_project/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    # Cloudflare Pages Project resource module that self-registers
    module CloudflarePagesProject
      # Create a Cloudflare Pages Project
      #
      # Pages projects host static sites and full-stack applications on
      # Cloudflare's global network with integrated CI/CD, Workers runtime,
      # and service bindings.
      #
      # Supports GitHub/GitLab integration, custom build commands, environment
      # variables, and Workers bindings (KV, D1, R2, Durable Objects, etc.).
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Pages project attributes
      # @option attributes [String] :account_id Account ID (required)
      # @option attributes [String] :name Project name (required)
      # @option attributes [String] :production_branch Production branch
      # @option attributes [Hash] :build_config Build configuration
      # @option attributes [Hash] :source Source repository configuration
      # @option attributes [Hash] :deployment_configs Deployment configurations
      #
      # @return [ResourceReference] Reference object with outputs
      #
      # @example Static site with build configuration
      #   cloudflare_pages_project(:my_site, {
      #     account_id: "a" * 32,
      #     name: "my-static-site",
      #     production_branch: "main",
      #     build_config: {
      #       build_command: "npm run build",
      #       destination_dir: "dist",
      #       root_dir: "/"
      #     }
      #   })
      #
      # @example Full-stack app with GitHub integration
      #   cloudflare_pages_project(:my_app, {
      #     account_id: "a" * 32,
      #     name: "my-app",
      #     production_branch: "main",
      #     source: {
      #       type: "github",
      #       config: {
      #         owner: "myorg",
      #         repo_name: "myrepo",
      #         production_branch: "main",
      #         deployments_enabled: true,
      #         pr_comments_enabled: true
      #       }
      #     },
      #     build_config: {
      #       build_command: "npm run build",
      #       destination_dir: "build"
      #     }
      #   })
      #
      # @example Pages with Workers bindings
      #   cloudflare_pages_project(:workers_app, {
      #     account_id: "a" * 32,
      #     name: "workers-app",
      #     production_branch: "main",
      #     deployment_configs: {
      #       production: {
      #         compatibility_date: "2025-01-01",
      #         env_vars: {
      #           "API_KEY" => { type: "secret_text", value: "secret" }
      #         },
      #         kv_namespaces: {
      #           "MY_KV" => { namespace_id: "abc123" }
      #         },
      #         d1_databases: {
      #           "MY_DB" => { id: "def456" }
      #         }
      #       }
      #     }
      #   })
      def cloudflare_pages_project(name, attributes = {})
        # Validate attributes using dry-struct
        project_attrs = Cloudflare::Types::PagesProjectAttributes.new(attributes)

        # Generate terraform resource block via terraform-synthesizer
        resource(:cloudflare_pages_project, name) do
          account_id project_attrs.account_id
          name project_attrs.name
          production_branch project_attrs.production_branch if project_attrs.production_branch

          # Build configuration
          if project_attrs.build_config
            build_config do
              build_command project_attrs.build_config.build_command if project_attrs.build_config.build_command
              destination_dir project_attrs.build_config.destination_dir if project_attrs.build_config.destination_dir
              root_dir project_attrs.build_config.root_dir if project_attrs.build_config.root_dir
              build_caching project_attrs.build_config.build_caching if project_attrs.build_config.build_caching
              web_analytics_tag project_attrs.build_config.web_analytics_tag if project_attrs.build_config.web_analytics_tag
              web_analytics_token project_attrs.build_config.web_analytics_token if project_attrs.build_config.web_analytics_token
            end
          end

          # Source repository configuration
          if project_attrs.source
            source do
              type project_attrs.source.type

              config do
                owner project_attrs.source.config.owner
                repo_name project_attrs.source.config.repo_name
                production_branch project_attrs.source.config.production_branch if project_attrs.source.config.production_branch
                production_deployments_enabled project_attrs.source.config.production_deployments_enabled if project_attrs.source.config.production_deployments_enabled
                deployments_enabled project_attrs.source.config.deployments_enabled if project_attrs.source.config.deployments_enabled
                pr_comments_enabled project_attrs.source.config.pr_comments_enabled if project_attrs.source.config.pr_comments_enabled
                preview_deployment_setting project_attrs.source.config.preview_deployment_setting if project_attrs.source.config.preview_deployment_setting
                preview_branch_includes project_attrs.source.config.preview_branch_includes if project_attrs.source.config.preview_branch_includes
                preview_branch_excludes project_attrs.source.config.preview_branch_excludes if project_attrs.source.config.preview_branch_excludes
              end
            end
          end

          # Deployment configurations
          if project_attrs.deployment_configs
            deployment_configs do
              # Production deployment config
              if project_attrs.deployment_configs.production
                production do
                  synthesize_deployment_config(self, project_attrs.deployment_configs.production)
                end
              end

              # Preview deployment config
              if project_attrs.deployment_configs.preview
                preview do
                  synthesize_deployment_config(self, project_attrs.deployment_configs.preview)
                end
              end
            end
          end
        end

        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'cloudflare_pages_project',
          name: name,
          resource_attributes: project_attrs.to_h,
          outputs: {
            id: "${cloudflare_pages_project.#{name}.id}",
            subdomain: "${cloudflare_pages_project.#{name}.subdomain}",
            domains: "${cloudflare_pages_project.#{name}.domains}",
            created_on: "${cloudflare_pages_project.#{name}.created_on}"
          }
        )
      end

      private

      # Helper method to synthesize deployment configuration
      def synthesize_deployment_config(context, config)
        context.instance_eval do
          compatibility_date config.compatibility_date if config.compatibility_date
          compatibility_flags config.compatibility_flags if config.compatibility_flags
          build_image_major_version config.build_image_major_version if config.build_image_major_version
          always_use_latest_compatibility_date config.always_use_latest_compatibility_date if config.always_use_latest_compatibility_date
          fail_open config.fail_open if config.fail_open
          usage_model config.usage_model if config.usage_model

          # Environment variables
          if config.env_vars
            config.env_vars.each do |var_name, var_config|
              env_vars do
                name var_name
                value var_config.value
                type var_config.type
              end
            end
          end

          # KV namespaces
          if config.kv_namespaces
            config.kv_namespaces.each do |binding_name, binding_config|
              kv_namespaces do
                name binding_name
                namespace_id binding_config[:namespace_id] || binding_config['namespace_id']
              end
            end
          end

          # D1 databases
          if config.d1_databases
            config.d1_databases.each do |binding_name, binding_config|
              d1_databases do
                name binding_name
                id binding_config[:id] || binding_config['id']
              end
            end
          end

          # Durable Object namespaces
          if config.durable_object_namespaces
            config.durable_object_namespaces.each do |binding_name, binding_config|
              durable_object_namespaces do
                name binding_name
                namespace_id binding_config[:namespace_id] || binding_config['namespace_id']
              end
            end
          end

          # R2 buckets
          if config.r2_buckets
            config.r2_buckets.each do |binding_name, binding_config|
              r2_buckets do
                name binding_name
                bucket_name binding_config.bucket_name
                jurisdiction binding_config.jurisdiction if binding_config.jurisdiction
              end
            end
          end

          # Service bindings
          if config.services
            config.services.each do |binding_name, binding_config|
              services do
                name binding_name
                service binding_config.service
                environment binding_config.environment if binding_config.environment
                entrypoint binding_config.entrypoint if binding_config.entrypoint
              end
            end
          end

          # Analytics Engine datasets
          if config.analytics_engine_datasets
            config.analytics_engine_datasets.each do |binding_name, binding_config|
              analytics_engine_datasets do
                name binding_name
                dataset binding_config[:dataset] || binding_config['dataset']
              end
            end
          end

          # Queue producers
          if config.queue_producers
            config.queue_producers.each do |binding_name, binding_config|
              queue_producers do
                name binding_name
                binding_name binding_config[:name] || binding_config['name'] || binding_name
              end
            end
          end

          # Hyperdrive bindings
          if config.hyperdrive_bindings
            config.hyperdrive_bindings.each do |binding_name, binding_config|
              hyperdrive_bindings do
                name binding_name
                id binding_config[:id] || binding_config['id']
              end
            end
          end

          # Vectorize bindings
          if config.vectorize_bindings
            config.vectorize_bindings.each do |binding_name, binding_config|
              vectorize_bindings do
                name binding_name
                index_name binding_config[:index_name] || binding_config['index_name']
              end
            end
          end

          # AI bindings
          if config.ai_bindings
            config.ai_bindings.each do |binding_name, binding_config|
              ai_bindings do
                name binding_name
                project_id binding_config[:project_id] || binding_config['project_id'] if binding_config[:project_id] || binding_config['project_id']
              end
            end
          end

          # Browser bindings
          if config.browsers
            config.browsers.each do |binding_name, _binding_config|
              browsers do
                name binding_name
              end
            end
          end

          # mTLS certificates
          if config.mtls_certificates
            config.mtls_certificates.each do |binding_name, binding_config|
              mtls_certificates do
                name binding_name
                certificate_id binding_config[:certificate_id] || binding_config['certificate_id']
              end
            end
          end

          # Limits
          if config.limits
            limits do
              cpu_ms config.limits.cpu_ms if config.limits.cpu_ms
            end
          end

          # Placement
          if config.placement
            placement do
              mode config.placement.mode
            end
          end
        end
      end
    end

    # Maintain backward compatibility by extending Cloudflare module
    module Cloudflare
      include CloudflarePagesProject
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register_module(Pangea::Resources::Cloudflare)
