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
    module CarbonAwareCompute
      # Shared helper methods for Carbon Aware Compute components
      module Helpers
        def component_tags(input)
          input.tags.merge("Component" => "carbon-aware-compute")
        end

        def function_tags(input, function_name)
          component_tags(input).merge("Function" => function_name)
        end

        def table_tags(input, purpose)
          component_tags(input).merge("Purpose" => purpose)
        end

        def lambda_architecture(input)
          input.use_graviton ? ["arm64"] : ["x86_64"]
        end

        def base_assume_role_policy(service)
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Principal: { Service: service },
              Action: "sts:AssumeRole"
            }]
          })
        end

        def generate_inline_policy(name, statements)
          [{
            name: name,
            policy: JSON.pretty_generate({
              Version: "2012-10-17",
              Statement: statements
            })
          }]
        end
      end
    end
  end
end
