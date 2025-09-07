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
      # Type-safe attributes for AWS CodePipeline resources
      class CodePipelineAttributes < Dry::Struct
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
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate pipeline has at least one source action
          source_actions = attrs.stages.flat_map { |s| s[:actions] }.select { |a| a[:action_type_id][:category] == 'Source' }
          if source_actions.empty?
            raise Dry::Struct::Error, "Pipeline must have at least one Source action"
          end

          # Validate artifact names are unique
          all_artifacts = attrs.stages.flat_map do |stage|
            stage[:actions].flat_map do |action|
              (action[:input_artifacts] || []) + (action[:output_artifacts] || [])
            end
          end
          if all_artifacts.size != all_artifacts.uniq.size
            duplicate_artifacts = all_artifacts.select { |a| all_artifacts.count(a) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate artifact names found: #{duplicate_artifacts.join(', ')}"
          end

          # Validate action names are unique within pipeline
          all_action_names = attrs.stages.flat_map { |s| s[:actions].map { |a| a[:name] } }
          if all_action_names.size != all_action_names.uniq.size
            duplicate_actions = all_action_names.select { |a| all_action_names.count(a) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate action names found: #{duplicate_actions.join(', ')}"
          end

          # Validate stage names are unique
          stage_names = attrs.stages.map { |s| s[:name] }
          if stage_names.size != stage_names.uniq.size
            duplicate_stages = stage_names.select { |s| stage_names.count(s) > 1 }.uniq
            raise Dry::Struct::Error, "Duplicate stage names found: #{duplicate_stages.join(', ')}"
          end

          # Validate artifact flow (outputs must be produced before inputs)
          attrs.validate_artifact_flow!

          attrs
        end

        # Validate artifact flow through pipeline
        def validate_artifact_flow!
          produced_artifacts = Set.new

          stages.each_with_index do |stage, stage_index|
            stage[:actions].each do |action|
              # Check input artifacts are already produced
              if action[:input_artifacts]
                action[:input_artifacts].each do |artifact|
                  unless produced_artifacts.include?(artifact)
                    raise Dry::Struct::Error, "Action '#{action[:name]}' in stage '#{stage[:name]}' requires artifact '#{artifact}' which hasn't been produced yet"
                  end
                end
              end

              # Add output artifacts to produced set
              if action[:output_artifacts]
                action[:output_artifacts].each do |artifact|
                  if produced_artifacts.include?(artifact)
                    raise Dry::Struct::Error, "Artifact '#{artifact}' is produced multiple times"
                  end
                  produced_artifacts.add(artifact)
                end
              end
            end
          end
        end

        # Helper methods
        def stage_count
          stages.size
        end

        def action_count
          stages.sum { |s| s[:actions].size }
        end

        def uses_encryption?
          artifact_store[:encryption_key].present?
        end

        def source_providers
          stages.flat_map { |s| s[:actions] }
            .select { |a| a[:action_type_id][:category] == 'Source' }
            .map { |a| a[:action_type_id][:provider] }
            .uniq
        end

        def build_providers
          stages.flat_map { |s| s[:actions] }
            .select { |a| a[:action_type_id][:category] == 'Build' }
            .map { |a| a[:action_type_id][:provider] }
            .uniq
        end

        def deploy_providers
          stages.flat_map { |s| s[:actions] }
            .select { |a| a[:action_type_id][:category] == 'Deploy' }
            .map { |a| a[:action_type_id][:provider] }
            .uniq
        end

        def has_manual_approval?
          stages.any? do |stage|
            stage[:actions].any? { |a| a[:action_type_id][:category] == 'Approval' }
          end
        end

        def cross_region_actions
          stages.flat_map { |s| s[:actions] }
            .select { |a| a[:region].present? }
            .map { |a| { name: a[:name], region: a[:region] } }
        end

        def artifact_flow_diagram
          flow = []
          stages.each do |stage|
            stage[:actions].each do |action|
              inputs = action[:input_artifacts] || []
              outputs = action[:output_artifacts] || []
              flow << {
                stage: stage[:name],
                action: action[:name],
                inputs: inputs,
                outputs: outputs
              }
            end
          end
          flow
        end
      end
    end
      end
    end
  end
end