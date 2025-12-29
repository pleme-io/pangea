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
  module Components
    module GreenDataLifecycle
      # Shared helper methods for Green Data Lifecycle component
      module Helpers
        private

        def component_tags(input)
          input.tags.merge("Component" => "green-data-lifecycle")
        end

        def storage_tags(input, purpose)
          component_tags(input).merge(
            "Purpose" => purpose,
            "Sustainability" => purpose == "archive-storage" ? "optimized" : "enabled"
          )
        end

        def function_tags(input, function_name)
          component_tags(input).merge("Function" => function_name)
        end
      end
    end
  end
end
