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
      module EMRContainers
        # AWS EMR Containers Virtual Cluster resource
        # This resource manages an EMR on EKS virtual cluster, which enables you to run
        # big data analytics workloads on Amazon EKS using the EMR runtime. Virtual clusters
        # provide isolation, security, and flexibility for running Spark jobs on Kubernetes.
        #
        # @see https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/virtual-cluster.html
        module VirtualCluster
          # Creates an AWS EMR Containers Virtual Cluster
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the virtual cluster
          # @option attributes [String] :name The name of the virtual cluster (required)
          # @option attributes [Hash] :container_provider Configuration for the container provider (required)
          #   - :id [String] The namespace on the EKS cluster (required)
          #   - :type [String] The type of container provider (must be "EKS") (required)
          #   - :info [Hash] Container provider information
          #     - :eks_info [Hash] EKS-specific information
          #       - :namespace [String] The namespace where the virtual cluster will be created
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic virtual cluster for data processing
          #   aws_emrcontainers_virtual_cluster(:data_processing_cluster, {
          #     name: "data-processing-emr-cluster",
          #     container_provider: {
          #       id: "data-processing",
          #       type: "EKS",
          #       info: {
          #         eks_info: {
          #           namespace: "emr-data-processing"
          #         }
          #       }
          #     }
          #   })
          #
          # @example Production virtual cluster with tags
          #   aws_emrcontainers_virtual_cluster(:prod_analytics_cluster, {
          #     name: "production-analytics-cluster",
          #     container_provider: {
          #       id: "prod-analytics",
          #       type: "EKS",
          #       info: {
          #         eks_info: {
          #           namespace: "emr-analytics-prod"
          #         }
          #       }
          #     },
          #     tags: {
          #       Environment: "production",
          #       Team: "DataEngineering",
          #       Application: "Analytics",
          #       CostCenter: "BigData"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created virtual cluster
          def aws_emrcontainers_virtual_cluster(name, attributes = {})
            resource = resource(:aws_emrcontainers_virtual_cluster, name) do
              name attributes[:name] if attributes[:name]
              container_provider attributes[:container_provider] if attributes[:container_provider]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_emrcontainers_virtual_cluster',
              name: name,
              resource_attributes: attributes,
              outputs: {
                id: "${aws_emrcontainers_virtual_cluster.#{name}.id}",
                arn: "${aws_emrcontainers_virtual_cluster.#{name}.arn}",
                state: "${aws_emrcontainers_virtual_cluster.#{name}.state}",
                created_at: "${aws_emrcontainers_virtual_cluster.#{name}.created_at}"
              }
            )
          end
        end
      end
    end
  end
end