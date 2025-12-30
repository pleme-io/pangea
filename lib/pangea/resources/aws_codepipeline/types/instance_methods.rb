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
        # Instance methods for CodePipeline attributes
        module CodePipelineInstanceMethods
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
            actions_by_category('Source').map { |a| a[:action_type_id][:provider] }.uniq
          end

          def build_providers
            actions_by_category('Build').map { |a| a[:action_type_id][:provider] }.uniq
          end

          def deploy_providers
            actions_by_category('Deploy').map { |a| a[:action_type_id][:provider] }.uniq
          end

          def has_manual_approval?
            stages.any? do |stage|
              stage[:actions].any? { |a| a[:action_type_id][:category] == 'Approval' }
            end
          end

          def cross_region_actions
            all_actions
              .select { |a| a[:region].present? }
              .map { |a| { name: a[:name], region: a[:region] } }
          end

          def artifact_flow_diagram
            stages.flat_map do |stage|
              stage[:actions].map do |action|
                {
                  stage: stage[:name],
                  action: action[:name],
                  inputs: action[:input_artifacts] || [],
                  outputs: action[:output_artifacts] || []
                }
              end
            end
          end

          private

          def all_actions
            stages.flat_map { |s| s[:actions] }
          end

          def actions_by_category(category)
            all_actions.select { |a| a[:action_type_id][:category] == category }
          end
        end
      end
    end
  end
end
