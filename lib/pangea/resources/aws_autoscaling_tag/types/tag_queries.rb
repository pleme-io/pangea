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
        # Query methods for Auto Scaling Group tags
        module TagQueries
          # Computed properties
          def tag_count
            tags.length
          end

          def has_propagated_tags?
            tags.any?(&:propagate_at_launch)
          end

          def has_non_propagated_tags?
            tags.any? { |tag| !tag.propagate_at_launch }
          end

          def all_tags_propagated?
            tags.all?(&:propagate_at_launch)
          end

          def no_tags_propagated?
            tags.none?(&:propagate_at_launch)
          end

          def propagated_tag_count
            tags.count(&:propagate_at_launch)
          end

          def non_propagated_tag_count
            tags.count { |tag| !tag.propagate_at_launch }
          end

          def tag_keys
            tags.map(&:key)
          end

          def propagated_tag_keys
            tags.select(&:propagate_at_launch).map(&:key)
          end

          def non_propagated_tag_keys
            tags.reject(&:propagate_at_launch).map(&:key)
          end

          def has_tag?(key)
            tag_keys.include?(key)
          end

          def tag_value(key)
            tag = tags.find { |t| t.key == key }
            tag&.value
          end

          def tag_propagated?(key)
            tag = tags.find { |t| t.key == key }
            tag&.propagate_at_launch || false
          end

          # Standard tag queries
          def has_environment_tag?
            has_tag?('Environment') || has_tag?('environment')
          end

          def has_name_tag?
            has_tag?('Name') || has_tag?('name')
          end

          def has_cost_center_tag?
            has_tag?('CostCenter') || has_tag?('Cost-Center') || has_tag?('cost-center')
          end

          def has_owner_tag?
            has_tag?('Owner') || has_tag?('owner')
          end

          def has_project_tag?
            has_tag?('Project') || has_tag?('project')
          end

          def environment
            tag_value('Environment') || tag_value('environment')
          end

          def name
            tag_value('Name') || tag_value('name')
          end

          def cost_center
            tag_value('CostCenter') || tag_value('Cost-Center') || tag_value('cost-center')
          end

          def owner
            tag_value('Owner') || tag_value('owner')
          end

          def project
            tag_value('Project') || tag_value('project')
          end
        end
      end
    end
  end
end
