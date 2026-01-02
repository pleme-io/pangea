# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Queue configuration templates for AWS Batch Job Queue
        module BatchJobQueueTemplates
          PRIORITY_LEVELS = {
            critical: 1000,
            high: 900,
            medium_high: 750,
            medium: 500,
            medium_low: 250,
            low: 100,
            background: 1
          }.freeze

          def self.priority_levels = PRIORITY_LEVELS
          def self.critical_priority = PRIORITY_LEVELS[:critical]
          def self.high_priority = PRIORITY_LEVELS[:high]
          def self.medium_priority = PRIORITY_LEVELS[:medium]
          def self.low_priority = PRIORITY_LEVELS[:low]
          def self.background_priority = PRIORITY_LEVELS[:background]

          def self.high_priority_queue(name, compute_environments, options = {})
            {
              name: name,
              state: options[:state] || 'ENABLED',
              priority: options[:priority] || 900,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(Priority: 'high')
            }
          end

          def self.medium_priority_queue(name, compute_environments, options = {})
            {
              name: name,
              state: options[:state] || 'ENABLED',
              priority: options[:priority] || 500,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(Priority: 'medium')
            }
          end

          def self.low_priority_queue(name, compute_environments, options = {})
            {
              name: name,
              state: options[:state] || 'ENABLED',
              priority: options[:priority] || 100,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(Priority: 'low')
            }
          end

          def self.mixed_compute_queue(name, compute_env_configs, options = {})
            compute_order = compute_env_configs.map.with_index do |config, index|
              { order: config[:order] || index, compute_environment: config[:env] || config[:compute_environment] }
            end

            { name: name, state: options[:state] || 'ENABLED', priority: options[:priority] || 500, compute_environment_order: compute_order, tags: options[:tags] || {} }
          end

          def self.build_compute_environment_order(compute_environments)
            case compute_environments
            when String
              [{ order: 1, compute_environment: compute_environments }]
            when Array
              if compute_environments.first.is_a?(String)
                compute_environments.map.with_index { |env, index| { order: index + 1, compute_environment: env } }
              else
                compute_environments
              end
            when Hash
              [compute_environments]
            else
              raise Dry::Struct::Error, 'Invalid compute environment configuration'
            end
          end

          def self.queue_naming_patterns
            {
              production: ->(workload) { "prod-#{workload}-queue" },
              staging: ->(workload) { "staging-#{workload}-queue" },
              development: ->(workload) { "dev-#{workload}-queue" },
              priority_based: ->(priority, workload) { "#{priority}-priority-#{workload}-queue" },
              team_based: ->(team, workload) { "#{team}-#{workload}-queue" },
              environment_based: ->(env, priority, workload) { "#{env}-#{priority}-#{workload}-queue" }
            }
          end

          def self.data_processing_queue(name, compute_environments, priority = :medium, options = {})
            { name: name, state: 'ENABLED', priority: PRIORITY_LEVELS[priority] || priority, compute_environment_order: build_compute_environment_order(compute_environments), tags: (options[:tags] || {}).merge(Workload: 'data-processing', Type: 'batch', Priority: priority.to_s) }
          end

          def self.ml_training_queue(name, compute_environments, options = {})
            { name: name, state: 'ENABLED', priority: options[:priority] || PRIORITY_LEVELS[:high], compute_environment_order: build_compute_environment_order(compute_environments), tags: (options[:tags] || {}).merge(Workload: 'ml-training', Type: 'gpu-intensive', Priority: 'high') }
          end

          def self.batch_processing_queue(name, compute_environments, options = {})
            { name: name, state: 'ENABLED', priority: options[:priority] || PRIORITY_LEVELS[:medium_low], compute_environment_order: build_compute_environment_order(compute_environments), tags: (options[:tags] || {}).merge(Workload: 'batch-processing', Type: 'background', Priority: 'medium-low') }
          end

          def self.real_time_queue(name, compute_environments, options = {})
            { name: name, state: 'ENABLED', priority: options[:priority] || PRIORITY_LEVELS[:critical], compute_environment_order: build_compute_environment_order(compute_environments), tags: (options[:tags] || {}).merge(Workload: 'real-time', Type: 'latency-sensitive', Priority: 'critical') }
          end

          def self.environment_queue_set(base_name, compute_environments_by_env, options = {})
            priorities = { production: :high, staging: :medium, development: :low }
            queues = {}

            %i[production staging development].each do |env|
              next unless compute_environments_by_env[env]

              queues[env] = {
                name: "#{env}-#{base_name}-queue",
                state: 'ENABLED',
                priority: PRIORITY_LEVELS[priorities[env]],
                compute_environment_order: build_compute_environment_order(compute_environments_by_env[env]),
                tags: (options[:tags] || {}).merge(Environment: env.to_s, Priority: priorities[env].to_s, Workload: base_name)
              }
            end

            queues
          end
        end
      end
    end
  end
end
