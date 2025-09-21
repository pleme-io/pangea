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
    module AWS
      module Types
      # Type-safe attributes for AWS CodeCommit Repository resources
      class CodeCommitRepositoryAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Repository name (required)
        attribute :repository_name, Resources::Types::String.constrained(
          format: /\A[\w.-]+\z/,
          max_size: 100
        )

        # Repository description (optional)
        attribute? :description, Resources::Types::String.constrained(max_size: 1000).optional

        # Default branch name (defaults to 'main')
        attribute :default_branch, Resources::Types::String.default('main')

        # KMS key ARN for encryption (optional, uses AWS managed key by default)
        attribute? :kms_key_id, Resources::Types::String.optional

        # Trigger configuration
        attribute :triggers, Resources::Types::Array.of(
          Resources::Types::Hash.schema(
            name: Resources::Types::String.constrained(max_size: 100),
            destination_arn: Resources::Types::String,
            custom_data?: Resources::Types::String.optional,
            branches?: Resources::Types::Array.of(Resources::Types::String).optional,
            events: Resources::Types::Array.of(
              Resources::Types::String.enum('all', 'updateReference', 'createReference', 'deleteReference')
            )
          )
        ).default([].freeze)

        # Tags
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate repository name doesn't start/end with dash or dot
          if attrs.repository_name.start_with?('-', '.') || attrs.repository_name.end_with?('-', '.')
            raise Dry::Struct::Error, "Repository name cannot start or end with '-' or '.'"
          end

          # Validate triggers have unique names
          trigger_names = attrs.triggers.map { |t| t[:name] }
          if trigger_names.size != trigger_names.uniq.size
            raise Dry::Struct::Error, "Trigger names must be unique"
          end

          # Validate each trigger
          attrs.triggers.each do |trigger|
            # If branches specified, at least one must be provided
            if trigger[:branches] && trigger[:branches].empty?
              raise Dry::Struct::Error, "Trigger '#{trigger[:name]}' must specify at least one branch if branches array is provided"
            end

            # Validate destination ARN format
            unless trigger[:destination_arn].match?(/^arn:aws/)
              raise Dry::Struct::Error, "Trigger '#{trigger[:name]}' destination_arn must be a valid AWS ARN"
            end
          end

          attrs
        end

        # Helper methods
        def encrypted?
          kms_key_id.present?
        end

        def has_triggers?
          triggers.any?
        end

        def trigger_count
          triggers.size
        end

        def trigger_names
          triggers.map { |t| t[:name] }
        end

        def all_trigger_events
          triggers.flat_map { |t| t[:events] }.uniq.sort
        end

        def triggers_for_branch(branch_name)
          triggers.select do |trigger|
            # If no branches specified, trigger applies to all branches
            trigger[:branches].nil? || trigger[:branches].include?(branch_name)
          end
        end
      end
    end
      end
    end
  end
end