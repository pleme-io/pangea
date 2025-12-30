# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/cloudflare_pages_project/types'

module Pangea
  module Resources
    module CloudflarePagesProject
      # Create a Cloudflare Pages Project
      def cloudflare_pages_project(name, attributes = {})
        project_attrs = Cloudflare::Types::PagesProjectAttributes.new(attributes)

        resource(:cloudflare_pages_project, name) do
          account_id project_attrs.account_id
          name project_attrs.name
          production_branch project_attrs.production_branch if project_attrs.production_branch

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

          if project_attrs.deployment_configs
            deployment_configs do
              if project_attrs.deployment_configs.production
                production { synthesize_deployment_config(self, project_attrs.deployment_configs.production) }
              end
              if project_attrs.deployment_configs.preview
                preview { synthesize_deployment_config(self, project_attrs.deployment_configs.preview) }
              end
            end
          end
        end

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
    end
  end
end
