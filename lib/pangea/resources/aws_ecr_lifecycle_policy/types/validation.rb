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
        class ECRLifecyclePolicyAttributes
          # Validation methods for ECR lifecycle policy
          module Validation
            def self.validate_lifecycle_rule(rule, idx)
              unless rule.is_a?(Hash)
                raise Dry::Struct::Error, "Rule[#{idx}] must be a hash"
              end

              unless rule['rulePriority'] && rule['rulePriority'].is_a?(Integer)
                raise Dry::Struct::Error, "Rule[#{idx}] must have an integer rulePriority"
              end

              unless rule['selection']
                raise Dry::Struct::Error, "Rule[#{idx}] must have a selection block"
              end

              unless rule['action']
                raise Dry::Struct::Error, "Rule[#{idx}] must have an action block"
              end

              validate_selection(rule['selection'], idx)
              validate_action(rule['action'], idx)
            end

            def self.validate_selection(selection, idx)
              unless selection['tagStatus']
                raise Dry::Struct::Error, "Rule[#{idx}] selection must specify tagStatus"
              end

              unless %w[tagged untagged any].include?(selection['tagStatus'])
                raise Dry::Struct::Error, "Rule[#{idx}] tagStatus must be 'tagged', 'untagged', or 'any'"
              end

              if selection['countType'] && !%w[imageCountMoreThan sinceImagePushed].include?(selection['countType'])
                raise Dry::Struct::Error, "Rule[#{idx}] countType must be 'imageCountMoreThan' or 'sinceImagePushed'"
              end
            end

            def self.validate_action(action, idx)
              unless action['type'] == 'expire'
                raise Dry::Struct::Error, "Rule[#{idx}] action type must be 'expire'"
              end
            end
          end
        end
      end
    end
  end
end
