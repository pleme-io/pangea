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
        # Helper methods for BatchComputeEnvironmentAttributes
        module BatchComputeEnvironmentHelpers
          def is_managed?
            type == "MANAGED"
          end

          def is_unmanaged?
            type == "UNMANAGED"
          end

          def is_enabled?
            state == "ENABLED"
          end

          def is_disabled?
            state == "DISABLED"
          end

          def supports_ec2?
            compute_resources && %w[EC2 SPOT].include?(compute_resources[:type])
          end

          def supports_fargate?
            compute_resources && %w[FARGATE FARGATE_SPOT].include?(compute_resources[:type])
          end

          def is_spot_based?
            compute_resources && %w[SPOT FARGATE_SPOT].include?(compute_resources[:type])
          end
        end
      end
    end
  end
end
