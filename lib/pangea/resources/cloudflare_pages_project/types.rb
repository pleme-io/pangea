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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Build configuration for Pages project
        class PagesBuildConfig < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute build_command
          #   @return [String, nil] Command executed during build phase
          attribute :build_command, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute destination_dir
          #   @return [String, nil] Output directory for built assets
          attribute :destination_dir, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute root_dir
          #   @return [String, nil] Project root directory path
          attribute :root_dir, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute build_caching
          #   @return [Boolean, nil] Enable build result caching
          attribute :build_caching, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute web_analytics_tag
          #   @return [String, nil] Analytics tracking identifier
          attribute :web_analytics_tag, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute web_analytics_token
          #   @return [String, nil] Analytics authentication token
          attribute :web_analytics_token, Dry::Types['strict.string'].optional.default(nil)
        end

        # Source repository configuration
        class PagesSourceConfig < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute owner
          #   @return [String] Repository owner/organization
          attribute :owner, Dry::Types['strict.string']

          # @!attribute repo_name
          #   @return [String] Repository name
          attribute :repo_name, Dry::Types['strict.string']

          # @!attribute production_branch
          #   @return [String, nil] Production deployment branch
          attribute :production_branch, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute production_deployments_enabled
          #   @return [Boolean, nil] Enable production deployments
          attribute :production_deployments_enabled, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute deployments_enabled
          #   @return [Boolean, nil] Enable all deployments
          attribute :deployments_enabled, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute pr_comments_enabled
          #   @return [Boolean, nil] Enable pull request comments
          attribute :pr_comments_enabled, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute preview_deployment_setting
          #   @return [String, nil] Preview deployment behavior
          attribute :preview_deployment_setting, Dry::Types['strict.string']
            .enum('none', 'all', 'custom')
            .optional
            .default(nil)

          # @!attribute preview_branch_includes
          #   @return [Array<String>, nil] Preview branch patterns
          attribute :preview_branch_includes, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute preview_branch_excludes
          #   @return [Array<String>, nil] Excluded preview branches
          attribute :preview_branch_excludes, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)
        end

        # Source repository definition
        class PagesSource < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute type
          #   @return [String] Repository type
          attribute :type, Dry::Types['strict.string'].enum('github', 'gitlab')

          # @!attribute config
          #   @return [PagesSourceConfig] Source configuration
          attribute :config, PagesSourceConfig
        end

        # Service binding for Pages deployment
        class PagesServiceBinding < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute name
          #   @return [String] Binding name
          attribute :name, Dry::Types['strict.string']

          # @!attribute service
          #   @return [String] Service name
          attribute :service, Dry::Types['strict.string']

          # @!attribute environment
          #   @return [String, nil] Service environment
          attribute :environment, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute entrypoint
          #   @return [String, nil] Service entrypoint
          attribute :entrypoint, Dry::Types['strict.string'].optional.default(nil)
        end

        # R2 bucket binding
        class PagesR2Binding < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute name
          #   @return [String] Binding name
          attribute :name, Dry::Types['strict.string']

          # @!attribute bucket_name
          #   @return [String] R2 bucket name
          attribute :bucket_name, Dry::Types['strict.string']

          # @!attribute jurisdiction
          #   @return [String, nil] Data jurisdiction
          attribute :jurisdiction, Dry::Types['strict.string'].optional.default(nil)
        end

        # Environment variable configuration
        class PagesEnvVar < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute type
          #   @return [String] Variable type
          attribute :type, Dry::Types['strict.string'].enum('plain_text', 'secret_text')

          # @!attribute value
          #   @return [String] Variable value
          attribute :value, Dry::Types['strict.string']
        end

        # Resource limits for deployment
        class PagesDeploymentLimits < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute cpu_ms
          #   @return [Integer, nil] CPU milliseconds limit
          attribute :cpu_ms, Dry::Types['coercible.integer'].constrained(gteq: 1).optional.default(nil)
        end

        # Placement configuration
        class PagesDeploymentPlacement < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute mode
          #   @return [String] Placement mode
          attribute :mode, Dry::Types['strict.string'].enum('smart')
        end

        # Deployment configuration (for preview or production)
        class PagesDeploymentConfig < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute compatibility_date
          #   @return [String, nil] Cloudflare Workers compatibility date
          attribute :compatibility_date, Dry::Types['strict.string']
            .constrained(format: /\A\d{4}-\d{2}-\d{2}\z/)
            .optional
            .default(nil)

          # @!attribute compatibility_flags
          #   @return [Array<String>, nil] Feature compatibility flags
          attribute :compatibility_flags, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)

          # @!attribute build_image_major_version
          #   @return [Integer, nil] Build image version number
          attribute :build_image_major_version, Dry::Types['coercible.integer']
            .constrained(gteq: 1)
            .optional
            .default(nil)

          # @!attribute always_use_latest_compatibility_date
          #   @return [Boolean, nil] Auto-update compatibility date
          attribute :always_use_latest_compatibility_date, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute fail_open
          #   @return [Boolean, nil] Fail open on routing errors
          attribute :fail_open, Dry::Types['strict.bool'].optional.default(nil)

          # @!attribute usage_model
          #   @return [String, nil] Workers usage model
          attribute :usage_model, Dry::Types['strict.string']
            .enum('standard', 'bundled', 'unbound')
            .optional
            .default(nil)

          # @!attribute env_vars
          #   @return [Hash<String, PagesEnvVar>, nil] Environment variables
          attribute :env_vars, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], PagesEnvVar)
            .optional
            .default(nil)

          # @!attribute kv_namespaces
          #   @return [Hash<String, Hash>, nil] KV namespace bindings
          attribute :kv_namespaces, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute d1_databases
          #   @return [Hash<String, Hash>, nil] D1 database bindings
          attribute :d1_databases, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute durable_object_namespaces
          #   @return [Hash<String, Hash>, nil] Durable Object bindings
          attribute :durable_object_namespaces, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute r2_buckets
          #   @return [Hash<String, PagesR2Binding>, nil] R2 bucket bindings
          attribute :r2_buckets, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], PagesR2Binding)
            .optional
            .default(nil)

          # @!attribute services
          #   @return [Hash<String, PagesServiceBinding>, nil] Service bindings
          attribute :services, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], PagesServiceBinding)
            .optional
            .default(nil)

          # @!attribute analytics_engine_datasets
          #   @return [Hash<String, Hash>, nil] Analytics Engine bindings
          attribute :analytics_engine_datasets, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute queue_producers
          #   @return [Hash<String, Hash>, nil] Queue producer bindings
          attribute :queue_producers, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute hyperdrive_bindings
          #   @return [Hash<String, Hash>, nil] Hyperdrive bindings
          attribute :hyperdrive_bindings, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute vectorize_bindings
          #   @return [Hash<String, Hash>, nil] Vectorize bindings
          attribute :vectorize_bindings, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute ai_bindings
          #   @return [Hash<String, Hash>, nil] AI model bindings
          attribute :ai_bindings, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute browsers
          #   @return [Hash<String, Hash>, nil] Browser bindings
          attribute :browsers, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute mtls_certificates
          #   @return [Hash<String, Hash>, nil] mTLS certificate bindings
          attribute :mtls_certificates, Dry::Types['strict.hash'].optional.default(nil)

          # @!attribute limits
          #   @return [PagesDeploymentLimits, nil] Resource limits
          attribute :limits, PagesDeploymentLimits.optional.default(nil)

          # @!attribute placement
          #   @return [PagesDeploymentPlacement, nil] Placement configuration
          attribute :placement, PagesDeploymentPlacement.optional.default(nil)
        end

        # Deployment configurations container
        class PagesDeploymentConfigs < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute production
          #   @return [PagesDeploymentConfig, nil] Production deployment config
          attribute :production, PagesDeploymentConfig.optional.default(nil)

          # @!attribute preview
          #   @return [PagesDeploymentConfig, nil] Preview deployment config
          attribute :preview, PagesDeploymentConfig.optional.default(nil)
        end

        # Type-safe attributes for Cloudflare Pages Project
        #
        # Pages projects host static sites and full-stack applications
        # on Cloudflare's global network with integrated CI/CD.
        #
        # @example Static site with build configuration
        #   PagesProjectAttributes.new(
        #     account_id: "a" * 32,
        #     name: "my-static-site",
        #     production_branch: "main",
        #     build_config: {
        #       build_command: "npm run build",
        #       destination_dir: "dist",
        #       root_dir: "/"
        #     }
        #   )
        #
        # @example Full-stack app with GitHub source
        #   PagesProjectAttributes.new(
        #     account_id: "a" * 32,
        #     name: "my-app",
        #     production_branch: "main",
        #     source: {
        #       type: "github",
        #       config: {
        #         owner: "myorg",
        #         repo_name: "myrepo",
        #         production_branch: "main",
        #         deployments_enabled: true
        #       }
        #     }
        #   )
        class PagesProjectAttributes < Dry::Struct
          transform_keys(&:to_sym)

          # @!attribute account_id
          #   @return [String] The account ID
          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId

          # @!attribute name
          #   @return [String] Project name
          attribute :name, Dry::Types['strict.string'].constrained(min_size: 1)

          # @!attribute production_branch
          #   @return [String, nil] Git branch deployed to production
          attribute :production_branch, Dry::Types['strict.string'].optional.default(nil)

          # @!attribute build_config
          #   @return [PagesBuildConfig, nil] Build configuration
          attribute :build_config, PagesBuildConfig.optional.default(nil)

          # @!attribute source
          #   @return [PagesSource, nil] Source repository configuration
          attribute :source, PagesSource.optional.default(nil)

          # @!attribute deployment_configs
          #   @return [PagesDeploymentConfigs, nil] Deployment configurations
          attribute :deployment_configs, PagesDeploymentConfigs.optional.default(nil)

          # Check if project has source configured
          # @return [Boolean] true if source repository configured
          def has_source?
            !source.nil?
          end

          # Check if project has build configuration
          # @return [Boolean] true if build config provided
          def has_build_config?
            !build_config.nil?
          end

          # Check if project has deployment configs
          # @return [Boolean] true if deployment configs provided
          def has_deployment_configs?
            !deployment_configs.nil?
          end

          # Check if GitHub source
          # @return [Boolean] true if using GitHub
          def github_source?
            source&.type == 'github'
          end

          # Check if GitLab source
          # @return [Boolean] true if using GitLab
          def gitlab_source?
            source&.type == 'gitlab'
          end
        end
      end
    end
  end
end
