# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Batch Job Queue attributes with validation
        class BatchJobQueueAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Core attributes
          attribute :name, Resources::Types::String
          attribute :state, Resources::Types::String
          attribute :priority, Resources::Types::Integer
          attribute :compute_environment_order, Resources::Types::Array
          
          # Optional attributes
          attribute? :tags, Resources::Types::Hash.optional
          
          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate job queue name
            if attrs[:name]
              validate_job_queue_name(attrs[:name])
            end
            
            # Validate state
            if attrs[:state] && !%w[ENABLED DISABLED].include?(attrs[:state])
              raise Dry::Struct::Error, "Job queue state must be 'ENABLED' or 'DISABLED'"
            end
            
            # Validate priority
            if attrs[:priority]
              validate_priority(attrs[:priority])
            end
            
            # Validate compute environment order
            if attrs[:compute_environment_order]
              validate_compute_environment_order(attrs[:compute_environment_order])
            end
            
            super(attrs)
          end
          
          def self.validate_job_queue_name(name)
            # Name must be 1-128 characters
            if name.length < 1 || name.length > 128
              raise Dry::Struct::Error, "Job queue name must be between 1 and 128 characters"
            end
            
            # Must start with alphanumeric
            unless name.match?(/^[a-zA-Z0-9]/)
              raise Dry::Struct::Error, "Job queue name must start with an alphanumeric character"
            end
            
            # Must contain only alphanumeric, hyphens, and underscores
            unless name.match?(/^[a-zA-Z0-9\-_]+$/)
              raise Dry::Struct::Error, "Job queue name can only contain letters, numbers, hyphens, and underscores"
            end
            
            true
          end
          
          def self.validate_priority(priority)
            if priority < 0 || priority > 1000
              raise Dry::Struct::Error, "Job queue priority must be between 0 and 1000"
            end
            
            true
          end
          
          def self.validate_compute_environment_order(compute_envs)
            unless compute_envs.is_a?(Array) && !compute_envs.empty?
              raise Dry::Struct::Error, "Compute environment order must be a non-empty array"
            end
            
            compute_envs.each_with_index do |env, index|
              unless env.is_a?(Hash)
                raise Dry::Struct::Error, "Compute environment order item #{index} must be a hash"
              end
              
              # Validate required fields
              unless env[:order] && env[:compute_environment]
                raise Dry::Struct::Error, "Compute environment order item #{index} must have 'order' and 'compute_environment' fields"
              end
              
              # Validate order is integer
              unless env[:order].is_a?(Integer) && env[:order] >= 0
                raise Dry::Struct::Error, "Compute environment order must be a non-negative integer"
              end
              
              # Validate compute environment is string
              unless env[:compute_environment].is_a?(String) && !env[:compute_environment].empty?
                raise Dry::Struct::Error, "Compute environment must be a non-empty string"
              end
            end
            
            # Validate unique orders
            orders = compute_envs.map { |env| env[:order] }
            if orders.uniq.length != orders.length
              raise Dry::Struct::Error, "Compute environment orders must be unique"
            end
            
            true
          end
          
          # Computed properties
          def is_enabled?
            state == "ENABLED"
          end
          
          def is_disabled?
            state == "DISABLED"
          end
          
          def high_priority?
            priority >= 750
          end
          
          def medium_priority?
            priority >= 250 && priority < 750
          end
          
          def low_priority?
            priority < 250
          end
          
          def compute_environment_count
            compute_environment_order.length
          end
          
          def primary_compute_environment
            compute_environment_order.min_by { |env| env[:order] }
          end
          
          def ordered_compute_environments
            compute_environment_order.sort_by { |env| env[:order] }
          end
          
          # Queue configuration templates
          def self.high_priority_queue(name, compute_environments, options = {})
            {
              name: name,
              state: options[:state] || "ENABLED",
              priority: options[:priority] || 900,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(Priority: "high")
            }
          end
          
          def self.medium_priority_queue(name, compute_environments, options = {})
            {
              name: name,
              state: options[:state] || "ENABLED", 
              priority: options[:priority] || 500,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(Priority: "medium")
            }
          end
          
          def self.low_priority_queue(name, compute_environments, options = {})
            {
              name: name,
              state: options[:state] || "ENABLED",
              priority: options[:priority] || 100,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(Priority: "low")
            }
          end
          
          def self.mixed_compute_queue(name, compute_env_configs, options = {})
            # compute_env_configs: [{ env: "compute-env-1", order: 1 }, ...]
            compute_order = compute_env_configs.map.with_index do |config, index|
              {
                order: config[:order] || index,
                compute_environment: config[:env] || config[:compute_environment]
              }
            end
            
            {
              name: name,
              state: options[:state] || "ENABLED",
              priority: options[:priority] || 500,
              compute_environment_order: compute_order,
              tags: options[:tags] || {}
            }
          end
          
          def self.build_compute_environment_order(compute_environments)
            case compute_environments
            when String
              # Single compute environment
              [{ order: 1, compute_environment: compute_environments }]
            when Array
              if compute_environments.first.is_a?(String)
                # Array of compute environment names
                compute_environments.map.with_index do |env, index|
                  { order: index + 1, compute_environment: env }
                end
              else
                # Array of compute environment configs
                compute_environments
              end
            when Hash
              # Single compute environment config
              [compute_environments]
            else
              raise Dry::Struct::Error, "Invalid compute environment configuration"
            end
          end
          
          # Priority level helpers
          def self.priority_levels
            {
              critical: 1000,
              high: 900,
              medium_high: 750,
              medium: 500,
              medium_low: 250,
              low: 100,
              background: 1
            }
          end
          
          def self.critical_priority
            priority_levels[:critical]
          end
          
          def self.high_priority
            priority_levels[:high]
          end
          
          def self.medium_priority
            priority_levels[:medium]
          end
          
          def self.low_priority
            priority_levels[:low]
          end
          
          def self.background_priority
            priority_levels[:background]
          end
          
          # Common queue naming patterns
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
          
          # Workload-specific queue configurations
          def self.data_processing_queue(name, compute_environments, priority = :medium, options = {})
            {
              name: name,
              state: "ENABLED",
              priority: priority_levels[priority] || priority,
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(
                Workload: "data-processing",
                Type: "batch",
                Priority: priority.to_s
              )
            }
          end
          
          def self.ml_training_queue(name, compute_environments, options = {})
            {
              name: name,
              state: "ENABLED",
              priority: options[:priority] || priority_levels[:high], # ML training is typically high priority
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(
                Workload: "ml-training",
                Type: "gpu-intensive",
                Priority: "high"
              )
            }
          end
          
          def self.batch_processing_queue(name, compute_environments, options = {})
            {
              name: name,
              state: "ENABLED",
              priority: options[:priority] || priority_levels[:medium_low], # Batch can be lower priority
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(
                Workload: "batch-processing", 
                Type: "background",
                Priority: "medium-low"
              )
            }
          end
          
          def self.real_time_queue(name, compute_environments, options = {})
            {
              name: name,
              state: "ENABLED", 
              priority: options[:priority] || priority_levels[:critical], # Real-time is critical priority
              compute_environment_order: build_compute_environment_order(compute_environments),
              tags: (options[:tags] || {}).merge(
                Workload: "real-time",
                Type: "latency-sensitive",
                Priority: "critical"
              )
            }
          end
          
          # Multi-environment queue setup
          def self.environment_queue_set(base_name, compute_environments_by_env, options = {})
            environments = %i[production staging development]
            priorities = {
              production: :high,
              staging: :medium, 
              development: :low
            }
            
            queues = {}
            
            environments.each do |env|
              next unless compute_environments_by_env[env]
              
              queue_name = "#{env}-#{base_name}-queue"
              priority = priorities[env]
              
              queues[env] = {
                name: queue_name,
                state: "ENABLED",
                priority: priority_levels[priority],
                compute_environment_order: build_compute_environment_order(
                  compute_environments_by_env[env]
                ),
                tags: (options[:tags] || {}).merge(
                  Environment: env.to_s,
                  Priority: priority.to_s,
                  Workload: base_name
                )
              }
            end
            
            queues
          end
        end
      end
    end
  end
end