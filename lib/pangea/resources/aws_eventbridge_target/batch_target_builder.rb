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
      # Builder module for Batch target parameters in EventBridge targets
      module BatchTargetBuilder
        # Builds batch parameters block for EventBridge target
        # @param builder [Object] The DSL builder context
        # @param batch_params [Hash] Batch parameters configuration
        def build_batch_parameters(builder, batch_params)
          builder.batch_parameters do
            job_definition batch_params[:job_definition]
            job_name batch_params[:job_name]

            build_array_properties(self, batch_params[:array_properties]) if batch_params[:array_properties]
            build_retry_strategy(self, batch_params[:retry_strategy]) if batch_params[:retry_strategy]
          end
        end

        private

        def build_array_properties(builder, array_props)
          builder.array_properties do
            size array_props[:size] if array_props[:size]
          end
        end

        def build_retry_strategy(builder, retry_strategy)
          builder.retry_strategy do
            attempts retry_strategy[:attempts] if retry_strategy[:attempts]
          end
        end
      end
    end
  end
end
