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
        # Validation module for CodePipeline attributes
        module CodePipelineValidation
          # Validate artifact flow through pipeline
          def validate_artifact_flow!
            produced_artifacts = Set.new

            stages.each do |stage|
              stage[:actions].each do |action|
                validate_input_artifacts(action, stage, produced_artifacts)
                add_output_artifacts(action, produced_artifacts)
              end
            end
          end

          private

          def validate_input_artifacts(action, stage, produced_artifacts)
            return unless action[:input_artifacts]

            action[:input_artifacts].each do |artifact|
              next if produced_artifacts.include?(artifact)

              raise Dry::Struct::Error,
                    "Action '#{action[:name]}' in stage '#{stage[:name]}' " \
                    "requires artifact '#{artifact}' which hasn't been produced yet"
            end
          end

          def add_output_artifacts(action, produced_artifacts)
            return unless action[:output_artifacts]

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
  end
end
