# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Build configuration for Pages project
        class PagesBuildConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :build_command, Dry::Types['strict.string'].optional.default(nil)
          attribute :destination_dir, Dry::Types['strict.string'].optional.default(nil)
          attribute :root_dir, Dry::Types['strict.string'].optional.default(nil)
          attribute :build_caching, Dry::Types['strict.bool'].optional.default(nil)
          attribute :web_analytics_tag, Dry::Types['strict.string'].optional.default(nil)
          attribute :web_analytics_token, Dry::Types['strict.string'].optional.default(nil)
        end

        # Source repository configuration
        class PagesSourceConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :owner, Dry::Types['strict.string']
          attribute :repo_name, Dry::Types['strict.string']
          attribute :production_branch, Dry::Types['strict.string'].optional.default(nil)
          attribute :production_deployments_enabled, Dry::Types['strict.bool'].optional.default(nil)
          attribute :deployments_enabled, Dry::Types['strict.bool'].optional.default(nil)
          attribute :pr_comments_enabled, Dry::Types['strict.bool'].optional.default(nil)
          attribute :preview_deployment_setting, Dry::Types['strict.string']
            .enum('none', 'all', 'custom')
            .optional
            .default(nil)
          attribute :preview_branch_includes, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)
          attribute :preview_branch_excludes, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)
        end

        # Source repository definition
        class PagesSource < Dry::Struct
          transform_keys(&:to_sym)

          attribute :type, Dry::Types['strict.string'].enum('github', 'gitlab')
          attribute :config, PagesSourceConfig
        end
      end
    end
  end
end
