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

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS CodePipeline resources
        class CodePipelineAttributes < Dry::Struct
          include CodePipelineValidation
          include CodePipelineInstanceMethods

          transform_keys(&:to_sym)

          # Pipeline name (required)
          attribute :name, Resources::Types::String.constrained(
            format: /\A[A-Za-z0-9][A-Za-z0-9\-_]*\z/,
            min_size: 1,
            max_size: 100
          )

          # Role ARN (required)
          attribute :role_arn, Resources::Types::String

          # Artifact store configuration
          attribute :artifact_store, Resources::Types::Hash.schema(
            type: Resources::Types::String.enum('S3').default('S3'),
            location: Resources::Types::String,
            encryption_key?: Resources::Types::Hash.schema(
              id: Resources::Types::String,
              type: Resources::Types::String.enum('KMS').default('KMS')
            ).optional
          )

          # Stages configuration (required, min 2 stages)
          attribute :stages, Resources::Types::Array.of(
            Resources::Types::Hash.schema(
              name: Resources::Types::String.constrained(max_size: 100),
              actions: Resources::Types::Array.of(
                Resources::Types::Hash.schema(
                  name: Resources::Types::String.constrained(max_size: 100),
                  action_type_id: Resources::Types::Hash.schema(
                    category: Resources::Types::String.enum('Source', 'Build', 'Test', 'Deploy', 'Invoke', 'Approval'),
                    owner: Resources::Types::String.enum('AWS', 'ThirdParty', 'Custom'),
                    provider: Resources::Types::String,
                    version: Resources::Types::String
                  ),
                  configuration?: Resources::Types::Hash.optional,
                  input_artifacts?: Resources::Types::Array.of(Resources::Types::String).optional,
                  output_artifacts?: Resources::Types::Array.of(Resources::Types::String).optional,
                  run_order?: Resources::Types::Integer.constrained(gteq: 1, lteq: 999).optional,
                  role_arn?: Resources::Types::String.optional,
                  region?: Resources::Types::String.optional,
                  namespace?: Resources::Types::String.optional
                )
              ).constrained(min_size: 1)
            )
          ).constrained(min_size: 2)

          # Tags
          attribute :tags, Resources::Types::AwsTags.default({}.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
            validate_pipeline_structure(attrs)
            attrs.validate_artifact_flow!
            attrs
          end

          def self.validate_pipeline_structure(attrs)
            validate_source_actions(attrs)
            validate_unique_artifacts(attrs)
            validate_unique_action_names(attrs)
            validate_unique_stage_names(attrs)
          end

          def self.validate_source_actions(attrs)
            source_actions = attrs.stages.flat_map { |s| s[:actions] }
                                  .select { |a| a[:action_type_id][:category] == 'Source' }
            return unless source_actions.empty?

            raise Dry::Struct::Error, 'Pipeline must have at least one Source action'
          end

          def self.validate_unique_artifacts(attrs)
            all_artifacts = attrs.stages.flat_map do |stage|
              stage[:actions].flat_map do |action|
                (action[:input_artifacts] || []) + (action[:output_artifacts] || [])
              end
            end
            return if all_artifacts.size == all_artifacts.uniq.size

            duplicates = all_artifacts.select { |a| all_artifacts.count(a) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate artifact names found: #{duplicates.join(', ')}"
          end

          def self.validate_unique_action_names(attrs)
            all_action_names = attrs.stages.flat_map { |s| s[:actions].map { |a| a[:name] } }
            return if all_action_names.size == all_action_names.uniq.size

            duplicates = all_action_names.select { |a| all_action_names.count(a) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate action names found: #{duplicates.join(', ')}"
          end

          def self.validate_unique_stage_names(attrs)
            stage_names = attrs.stages.map { |s| s[:name] }
            return if stage_names.size == stage_names.uniq.size

            duplicates = stage_names.select { |s| stage_names.count(s) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate stage names found: #{duplicates.join(', ')}"
          end
        end
      end
    end
  end
end
