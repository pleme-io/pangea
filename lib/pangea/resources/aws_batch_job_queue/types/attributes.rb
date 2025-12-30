# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # AWS Batch Job Queue attributes with validation
        class BatchJobQueueAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :name, Resources::Types::String
          attribute :state, Resources::Types::String
          attribute :priority, Resources::Types::Integer
          attribute :compute_environment_order, Resources::Types::Array
          attribute? :tags, Resources::Types::Hash.optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            validate_job_queue_name(attrs[:name]) if attrs[:name]
            raise Dry::Struct::Error, "Job queue state must be 'ENABLED' or 'DISABLED'" if attrs[:state] && !%w[ENABLED DISABLED].include?(attrs[:state])
            validate_priority(attrs[:priority]) if attrs[:priority]
            validate_compute_environment_order(attrs[:compute_environment_order]) if attrs[:compute_environment_order]

            super(attrs)
          end

          def self.validate_job_queue_name(name)
            raise Dry::Struct::Error, 'Job queue name must be between 1 and 128 characters' if name.length < 1 || name.length > 128
            raise Dry::Struct::Error, 'Job queue name must start with an alphanumeric character' unless name.match?(/^[a-zA-Z0-9]/)
            raise Dry::Struct::Error, 'Job queue name can only contain letters, numbers, hyphens, and underscores' unless name.match?(/^[a-zA-Z0-9\-_]+$/)

            true
          end

          def self.validate_priority(priority)
            raise Dry::Struct::Error, 'Job queue priority must be between 0 and 1000' if priority < 0 || priority > 1000

            true
          end

          def self.validate_compute_environment_order(compute_envs)
            raise Dry::Struct::Error, 'Compute environment order must be a non-empty array' unless compute_envs.is_a?(Array) && !compute_envs.empty?

            compute_envs.each_with_index do |env, index|
              raise Dry::Struct::Error, "Compute environment order item #{index} must be a hash" unless env.is_a?(Hash)
              raise Dry::Struct::Error, "Compute environment order item #{index} must have 'order' and 'compute_environment' fields" unless env[:order] && env[:compute_environment]
              raise Dry::Struct::Error, 'Compute environment order must be a non-negative integer' unless env[:order].is_a?(Integer) && env[:order] >= 0
              raise Dry::Struct::Error, 'Compute environment must be a non-empty string' unless env[:compute_environment].is_a?(String) && !env[:compute_environment].empty?
            end

            orders = compute_envs.map { |env| env[:order] }
            raise Dry::Struct::Error, 'Compute environment orders must be unique' if orders.uniq.length != orders.length

            true
          end

          def is_enabled? = state == 'ENABLED'
          def is_disabled? = state == 'DISABLED'
          def high_priority? = priority >= 750
          def medium_priority? = priority >= 250 && priority < 750
          def low_priority? = priority < 250
          def compute_environment_count = compute_environment_order.length
          def primary_compute_environment = compute_environment_order.min_by { |env| env[:order] }
          def ordered_compute_environments = compute_environment_order.sort_by { |env| env[:order] }
        end
      end
    end
  end
end
