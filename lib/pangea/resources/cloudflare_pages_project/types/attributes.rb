# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'build_config'
require_relative 'deployment_config'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Type-safe attributes for Cloudflare Pages Project
        class PagesProjectAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)
          attribute :production_branch, Dry::Types['strict.string'].optional.default(nil)
          attribute :build_config, PagesBuildConfig.optional.default(nil)
          attribute :source, PagesSource.optional.default(nil)
          attribute :deployment_configs, PagesDeploymentConfigs.optional.default(nil)

          # Check if project has source configured
          def has_source?
            !source.nil?
          end

          # Check if project has build configuration
          def has_build_config?
            !build_config.nil?
          end

          # Check if project has deployment configs
          def has_deployment_configs?
            !deployment_configs.nil?
          end

          # Check if GitHub source
          def github_source?
            source&.type == 'github'
          end

          # Check if GitLab source
          def gitlab_source?
            source&.type == 'gitlab'
          end
        end
      end
    end
  end
end
