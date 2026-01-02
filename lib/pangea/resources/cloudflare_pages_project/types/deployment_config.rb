# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'bindings'

module Pangea
  module Resources
    module Cloudflare
      module Types
        # Resource limits for deployment
        class PagesDeploymentLimits < Dry::Struct
          transform_keys(&:to_sym)

          attribute :cpu_ms, Dry::Types['coercible.integer'].constrained(gteq: 1).optional.default(nil)
        end

        # Placement configuration
        class PagesDeploymentPlacement < Dry::Struct
          transform_keys(&:to_sym)

          attribute :mode, Dry::Types['strict.string'].enum('smart')
        end

        # Deployment configuration (for preview or production)
        class PagesDeploymentConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :compatibility_date, Dry::Types['strict.string']
            .constrained(format: /\A\d{4}-\d{2}-\d{2}\z/)
            .optional
            .default(nil)
          attribute :compatibility_flags, Dry::Types['strict.array']
            .of(Dry::Types['strict.string'])
            .optional
            .default(nil)
          attribute :build_image_major_version, Dry::Types['coercible.integer']
            .constrained(gteq: 1)
            .optional
            .default(nil)
          attribute :always_use_latest_compatibility_date, Dry::Types['strict.bool'].optional.default(nil)
          attribute :fail_open, Dry::Types['strict.bool'].optional.default(nil)
          attribute :usage_model, Dry::Types['strict.string']
            .enum('standard', 'bundled', 'unbound')
            .optional
            .default(nil)
          attribute :env_vars, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], PagesEnvVar)
            .optional
            .default(nil)
          attribute :kv_namespaces, Dry::Types['strict.hash'].optional.default(nil)
          attribute :d1_databases, Dry::Types['strict.hash'].optional.default(nil)
          attribute :durable_object_namespaces, Dry::Types['strict.hash'].optional.default(nil)
          attribute :r2_buckets, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], PagesR2Binding)
            .optional
            .default(nil)
          attribute :services, Dry::Types['strict.hash']
            .map(Dry::Types['strict.string'], PagesServiceBinding)
            .optional
            .default(nil)
          attribute :analytics_engine_datasets, Dry::Types['strict.hash'].optional.default(nil)
          attribute :queue_producers, Dry::Types['strict.hash'].optional.default(nil)
          attribute :hyperdrive_bindings, Dry::Types['strict.hash'].optional.default(nil)
          attribute :vectorize_bindings, Dry::Types['strict.hash'].optional.default(nil)
          attribute :ai_bindings, Dry::Types['strict.hash'].optional.default(nil)
          attribute :browsers, Dry::Types['strict.hash'].optional.default(nil)
          attribute :mtls_certificates, Dry::Types['strict.hash'].optional.default(nil)
          attribute :limits, PagesDeploymentLimits.optional.default(nil)
          attribute :placement, PagesDeploymentPlacement.optional.default(nil)
        end

        # Deployment configurations container
        class PagesDeploymentConfigs < Dry::Struct
          transform_keys(&:to_sym)

          attribute :production, PagesDeploymentConfig.optional.default(nil)
          attribute :preview, PagesDeploymentConfig.optional.default(nil)
        end
      end
    end
  end
end
