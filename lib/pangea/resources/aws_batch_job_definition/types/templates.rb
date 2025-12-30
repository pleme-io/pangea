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
        class BatchJobDefinitionAttributes
          # Job definition templates
          module Templates
            def self.simple_container_job(name, image, options = {})
              {
                job_definition_name: name,
                type: 'container',
                container_properties: {
                  image: image,
                  vcpus: options[:vcpus] || 1,
                  memory: options[:memory] || 512,
                  job_role_arn: options[:job_role_arn]
                }.compact,
                retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
                timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
                platform_capabilities: options[:platform_capabilities],
                tags: options[:tags] || {}
              }.compact
            end

            def self.fargate_container_job(name, image, options = {})
              {
                job_definition_name: name,
                type: 'container',
                platform_capabilities: ['FARGATE'],
                container_properties: {
                  image: image,
                  vcpus: options[:vcpus] || 1,
                  memory: options[:memory] || 512,
                  execution_role_arn: options[:execution_role_arn],
                  job_role_arn: options[:job_role_arn],
                  network_configuration: { assign_public_ip: options[:assign_public_ip] || 'DISABLED' },
                  fargate_platform_configuration: { platform_version: options[:platform_version] || 'LATEST' }
                }.compact,
                retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
                timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
                tags: options[:tags] || {}
              }.compact
            end

            def self.gpu_container_job(name, image, options = {})
              {
                job_definition_name: name,
                type: 'container',
                container_properties: {
                  image: image,
                  vcpus: options[:vcpus] || 4,
                  memory: options[:memory] || 8192,
                  job_role_arn: options[:job_role_arn],
                  resource_requirements: [{ type: 'GPU', value: (options[:gpu_count] || 1).to_s }]
                }.compact,
                retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
                timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
                tags: (options[:tags] || {}).merge(Hardware: 'gpu'),
                platform_capabilities: ['EC2']
              }.compact
            end

            def self.multinode_job(name, image, num_nodes, options = {})
              {
                job_definition_name: name,
                type: 'multinode',
                node_properties: {
                  main_node: options[:main_node] || 0,
                  num_nodes: num_nodes,
                  node_range_properties: [{
                    target_nodes: "0:#{num_nodes - 1}",
                    container: {
                      image: image,
                      vcpus: options[:vcpus] || 2,
                      memory: options[:memory] || 2048,
                      job_role_arn: options[:job_role_arn]
                    }.compact
                  }]
                },
                retry_strategy: options[:retry_attempts] ? { attempts: options[:retry_attempts] } : nil,
                timeout: options[:timeout_seconds] ? { attempt_duration_seconds: options[:timeout_seconds] } : nil,
                platform_capabilities: ['EC2'],
                tags: (options[:tags] || {}).merge(Type: 'multinode')
              }.compact
            end

            def self.data_processing_job(name, image, options = {})
              simple_container_job(name, image, {
                                     vcpus: options[:vcpus] || 2,
                                     memory: options[:memory] || 4096,
                                     retry_attempts: options[:retry_attempts] || 3,
                                     timeout_seconds: options[:timeout_seconds] || 3600,
                                     job_role_arn: options[:job_role_arn],
                                     platform_capabilities: options[:platform_capabilities],
                                     tags: (options[:tags] || {}).merge(Workload: 'data-processing', Type: 'cpu-intensive')
                                   })
            end

            def self.ml_training_job(name, image, options = {})
              gpu_container_job(name, image, {
                                  vcpus: options[:vcpus] || 8,
                                  memory: options[:memory] || 16_384,
                                  gpu_count: options[:gpu_count] || 1,
                                  retry_attempts: options[:retry_attempts] || 2,
                                  timeout_seconds: options[:timeout_seconds] || 14_400,
                                  job_role_arn: options[:job_role_arn],
                                  tags: (options[:tags] || {}).merge(Workload: 'ml-training', Hardware: 'gpu', Type: 'gpu-intensive')
                                })
            end

            def self.batch_processing_job(name, image, options = {})
              simple_container_job(name, image, {
                                     vcpus: options[:vcpus] || 1,
                                     memory: options[:memory] || 1024,
                                     retry_attempts: options[:retry_attempts] || 5,
                                     timeout_seconds: options[:timeout_seconds] || 7200,
                                     job_role_arn: options[:job_role_arn],
                                     platform_capabilities: options[:platform_capabilities] || ['EC2'],
                                     tags: (options[:tags] || {}).merge(Workload: 'batch-processing', Priority: 'background', Type: 'background')
                                   })
            end

            def self.real_time_job(name, image, options = {})
              fargate_container_job(name, image, {
                                      vcpus: options[:vcpus] || 2,
                                      memory: options[:memory] || 2048,
                                      retry_attempts: options[:retry_attempts] || 1,
                                      timeout_seconds: options[:timeout_seconds] || 300,
                                      execution_role_arn: options[:execution_role_arn],
                                      job_role_arn: options[:job_role_arn],
                                      assign_public_ip: options[:assign_public_ip],
                                      tags: (options[:tags] || {}).merge(Workload: 'real-time', Latency: 'critical', Type: 'latency-sensitive')
                                    })
            end
          end
        end
      end
    end
  end
end
