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
        module_function

        # Returns a proc that builds batch parameters in DSL context
        # @param batch_params [Hash] Batch parameters configuration
        # @return [Proc] Block to be instance_exec'd in DSL context
        def batch_parameters_block(batch_params)
          proc do
            job_definition batch_params[:job_definition]
            job_name batch_params[:job_name]

            if batch_params[:array_properties]
              array_properties do
                size batch_params[:array_properties][:size] if batch_params[:array_properties][:size]
              end
            end

            if batch_params[:retry_strategy]
              retry_strategy do
                attempts batch_params[:retry_strategy][:attempts] if batch_params[:retry_strategy][:attempts]
              end
            end
          end
        end
      end
    end
  end
end
