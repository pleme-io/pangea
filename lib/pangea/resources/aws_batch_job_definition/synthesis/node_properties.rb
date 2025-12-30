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
      # Synthesis helpers for AWS Batch Job Definition node properties
      module BatchJobDefinitionNodeSynthesis
        private

        def synthesize_node_properties(node_props)
          node_properties do
            main_node node_props[:main_node]
            num_nodes node_props[:num_nodes]

            node_props[:node_range_properties].each do |node_range|
              node_range_properties do
                target_nodes node_range[:target_nodes]
                synthesize_node_container(node_range[:container]) if node_range[:container]
              end
            end
          end
        end

        def synthesize_node_container(container_config)
          container do
            image container_config[:image]
            vcpus container_config[:vcpus] if container_config[:vcpus]
            memory container_config[:memory] if container_config[:memory]
            job_role_arn container_config[:job_role_arn] if container_config[:job_role_arn]
            synthesize_node_environment(container_config[:environment]) if container_config[:environment]
          end
        end

        def synthesize_node_environment(env_vars)
          env_vars.each do |env_var|
            environment do
              name env_var[:name]
              value env_var[:value]
            end
          end
        end
      end
    end
  end
end
