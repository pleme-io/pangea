# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module CloudflarePagesProject
      private

      def synthesize_deployment_config(context, config)
        context.instance_eval do
          compatibility_date config.compatibility_date if config.compatibility_date
          compatibility_flags config.compatibility_flags if config.compatibility_flags
          build_image_major_version config.build_image_major_version if config.build_image_major_version
          always_use_latest_compatibility_date config.always_use_latest_compatibility_date if config.always_use_latest_compatibility_date
          fail_open config.fail_open if config.fail_open
          usage_model config.usage_model if config.usage_model

          config.env_vars&.each do |var_name, var_config|
            env_vars { name var_name; value var_config.value; type var_config.type }
          end

          config.kv_namespaces&.each do |binding_name, binding_config|
            kv_namespaces { name binding_name; namespace_id binding_config[:namespace_id] || binding_config['namespace_id'] }
          end

          config.d1_databases&.each do |binding_name, binding_config|
            d1_databases { name binding_name; id binding_config[:id] || binding_config['id'] }
          end

          config.durable_object_namespaces&.each do |binding_name, binding_config|
            durable_object_namespaces { name binding_name; namespace_id binding_config[:namespace_id] || binding_config['namespace_id'] }
          end

          config.r2_buckets&.each do |binding_name, binding_config|
            r2_buckets { name binding_name; bucket_name binding_config.bucket_name; jurisdiction binding_config.jurisdiction if binding_config.jurisdiction }
          end

          config.services&.each do |binding_name, binding_config|
            services { name binding_name; service binding_config.service; environment binding_config.environment if binding_config.environment; entrypoint binding_config.entrypoint if binding_config.entrypoint }
          end

          config.analytics_engine_datasets&.each do |binding_name, binding_config|
            analytics_engine_datasets { name binding_name; dataset binding_config[:dataset] || binding_config['dataset'] }
          end

          config.queue_producers&.each do |binding_name, binding_config|
            queue_producers { name binding_name; binding_name binding_config[:name] || binding_config['name'] || binding_name }
          end

          config.hyperdrive_bindings&.each do |binding_name, binding_config|
            hyperdrive_bindings { name binding_name; id binding_config[:id] || binding_config['id'] }
          end

          config.vectorize_bindings&.each do |binding_name, binding_config|
            vectorize_bindings { name binding_name; index_name binding_config[:index_name] || binding_config['index_name'] }
          end

          config.ai_bindings&.each do |binding_name, binding_config|
            ai_bindings { name binding_name; project_id binding_config[:project_id] || binding_config['project_id'] if binding_config[:project_id] || binding_config['project_id'] }
          end

          config.browsers&.each { |binding_name, _| browsers { name binding_name } }

          config.mtls_certificates&.each do |binding_name, binding_config|
            mtls_certificates { name binding_name; certificate_id binding_config[:certificate_id] || binding_config['certificate_id'] }
          end

          if config.limits
            limits { cpu_ms config.limits.cpu_ms if config.limits.cpu_ms }
          end

          if config.placement
            placement { mode config.placement.mode }
          end
        end
      end
    end
  end
end
